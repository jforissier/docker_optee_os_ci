# This Dockerfile creates an image suitable to run OP-TEE OS CI tests
# (xtest) in the QEMUv8 environment.
# In addition to pulling Ubuntu 21.04 plus all the required packages,
# it also clones the whole OP-TEE source tree for the QEMUv8 environment
# like any developer would typically do [1], and it builds everything twice:
# - First, with default flags
# - Second, with XEN_BOOT=y (i.e., with Normal World virtualization and
#   CFG_VIRTUALIZATION=y in optee_os)
# - Third, with OPTEE_RUST_ENABLE=y (building Teaclave SDK and examples)
# Doing so prepares the source tree for faster build + test with and without
# virtualization. The CI script can use this image and:
# 1. Run "repo sync" to obtain any update (likely to happen often for optee_*
# Gits, less likely for other projects such as the linux kernel, QEMU etc.)
# 2. Checkout the particular commit to be tested in optee_os
# 3. Run "make check"
# 4. Run "make check XEN_BOOT=y"
# In order to keep small build times, this image should be rebuilt on a regular
# basis such as for each OP-TEE release or when the qemu_v8.xml manifest [2]
# changes significantly.
#
# [1] https://optee.readthedocs.io/en/latest/building/devices/qemu.html#qemu-v8
# [2] https://github.com/OP-TEE/manifest/blob/master/qemu_v8.xml

FROM ubuntu as gcc-with-bti-builder
MAINTAINER Jerome Forissier <jerome@forissier.org>

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update \
 && apt upgrade -y \
 && apt install -y \
  binutils \
  build-essential \
  bison \
  flex \
  gawk \
  git \
  gcc \
  help2man \
  libncurses5-dev \
  libtool \
  libtool-bin \
  python3-dev \
  texinfo \
  unzip \
  wget

RUN useradd -ms /bin/bash nonroot
USER nonroot
WORKDIR /home/nonroot

# Build and install cross-compiler with BTI support in ~nonroot/x-tools/aarch64-unknown-linux-gnu/bin
RUN git clone https://github.com/crosstool-ng/crosstool-ng \
 && cd crosstool-ng \
 && ./bootstrap \
 && ./configure --enable-local \
 && make -j$(nproc) \
 && ./ct-ng aarch64-unknown-linux-gnu \
 && echo 'CT_CC_GCC_EXTRA_CONFIG_ARRAY="--enable-standard-branch-protection"' >>.config \
 && echo 'CT_CC_GCC_CORE_EXTRA_CONFIG_ARRAY="--enable-standard-branch-protection"' >>.config \
 && ./ct-ng build.$(nproc)

FROM ubuntu as clang-downloader
MAINTAINER Jerome Forissier <jerome@forissier.org>

RUN apt update && \
    apt install -y wget xz-utils

ADD get_clang.sh /root/get_clang.sh
WORKDIR /root
RUN ./get_clang.sh 12.0.0 ./clang

FROM ubuntu:21.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

COPY --from=clang-downloader /root/clang/ /usr/local/

RUN mkdir -p /root/x-tools
COPY --from=gcc-with-bti-builder /home/nonroot/x-tools /root/x-tools/

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y \
  acpica-tools \
  android-tools-fastboot \
  autoconf \
  bc \
  bison \
  bzip2 \
  ccache \
  cpio \
  curl \
  device-tree-compiler \
  expect \
  file \
  flex \
  g++ \
  gdisk \
  gettext \
  git \
  gpg \
  libattr1-dev \
  libcap-ng-dev \
  libglib2.0-dev \
  libguestfs-tools \
  libpixman-1-dev \
  linux-image-kvm \
  libssl-dev \
  lsb-release \
  make \
  ninja-build \
  pkg-config \
  python-is-python3 \
  python3 \
  python3-crypto \
  python3-cryptography \
  python3-distutils \
  python3-pycryptodome \
  python3-pyelftools \
  rsync \
  sudo \
  unzip \
  uuid-dev \
  vim \
  xz-utils \
  wget \
 && apt-get autoremove

RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
 && chmod a+x /usr/local/bin/repo \
 && git config --global user.name "CI user" \
 && git config --global user.email "ci@invalid" \
 && mkdir -p /root/optee_repo_qemu_v8

RUN cd /root/optee_repo_qemu_v8 \
 && repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml \
 && repo sync -j20

RUN cd /root/optee_repo_qemu_v8/build \
 && make -j2 toolchains

RUN cd /root/optee_repo_qemu_v8/build \
 && make -j$(getconf _NPROCESSORS_ONLN) XEN_BOOT=y

RUN cd /root/optee_repo_qemu_v8/build \
 && make -j$(getconf _NPROCESSORS_ONLN) OPTEE_RUST_ENABLE=y optee-rust \
 && /usr/bin/bash -c "source /root/.cargo/env && make -j$(getconf _NPROCESSORS_ONLN) OPTEE_RUST_ENABLE=y"

RUN cd /root/optee_repo_qemu_v8/build \
 && rm -rf ../out-br/build/optee* ../optee_os/out \
 && make -j$(nproc) CFG_CORE_BTI=y CFG_TA_BTI=y CFG_USER_TA_TARGETS=ta_arm64 AARCH64_CROSS_COMPILE=/root/x-tools/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu-

RUN cd /root/optee_repo_qemu_v8/build \
 && make arm-tf-clean \
 && rm -rf ../out-br/build/optee* ../optee_os/out \
 && make -j$(getconf _NPROCESSORS_ONLN)
