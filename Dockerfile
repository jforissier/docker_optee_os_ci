# This Dockerfile creates an image suitable to run OP-TEE OS CI tests
# in the QEMUv8 environment. It pulls Ubuntu plus all the required packages.
# In order to reduce CI build time, tt also clones the whole OP-TEE source
# tree for the QEMUv8 environment like any developer would typically do [1],
# and it builds some configurations so that the build cache (ccache) is
# populated and some images will usually not need to be rebuilt (the kernel,
# QEMU...).
# This image should be rebuilt on a regular basis such as when the kernel or
# any other "big" piece of software is updated.
#
# [1] https://optee.readthedocs.io/en/latest/building/devices/qemu.html#qemu-v8

FROM ubuntu as gcc-builder
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
 && ./ct-ng aarch64-unknown-linux-uclibc \
 && echo 'CT_CC_GCC_EXTRA_CONFIG_ARRAY="--enable-standard-branch-protection"' >>.config \
 && echo 'CT_CC_GCC_CORE_EXTRA_CONFIG_ARRAY="--enable-standard-branch-protection"' >>.config \
 && ./ct-ng build.$(nproc)

FROM ubuntu:22.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

RUN mkdir -p /usr/local
COPY --from=gcc-builder /home/nonroot/x-tools/aarch64-unknown-linux-uclibc /usr/local/

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
  cmake \
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
  libslirp-dev \
  libssl-dev \
  lsb-release \
  make \
  ninja-build \
  pkg-config \
  python-is-python3 \
  python3 \
  python3-cryptography \
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
 && mkdir -p /root/optee_repo_qemu_v8 \
 && cd /root/optee_repo_qemu_v8 \
 && repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml \
 && repo sync -j20 \
 && cd /root/optee_repo_qemu_v8/build \
 && make -j2 toolchains \
 && rm -f /root/optee_repo_qemu_v8/toolchains/gcc*.tar.xz \
 && make -j$(nproc) XEN_BOOT=y \
 && rm -rf out-br out-br-domu \
 && make arm-tf-clean \
 && make -j$(nproc)

COPY get_optee_qemuv8.sh /root

RUN chmod +x /root/get_optee_qemuv8.sh
