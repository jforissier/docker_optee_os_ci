# This Dockerfile creates an image suitable to run OP-TEE OS CI tests
# in the QEMU environment [1]. It pulls Ubuntu plus all the required
# packages.
#
# [1] https://optee.readthedocs.io/en/latest/building/devices/qemu.html

FROM ubuntu:22.04 as gcc-builder
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
# This particular commit of crosstool-ng builds GCC 12.2.0 by default which is what we want
# (13.x does not work with C++ TAs)
RUN git clone https://github.com/crosstool-ng/crosstool-ng \
 && cd crosstool-ng \
 && git checkout aa6cc4d7 \
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
  libgmp-dev \
  libguestfs-tools \
  libmpc-dev \
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
  python3-tomli \
  python3-venv \
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
 && git config --global user.email "ci@invalid"

COPY get_optee.sh /root

RUN chmod +rx /root
RUN chmod +x /root/get_optee.sh

ARG CLANG_BUILD_VER
COPY --from=optee_os_ci_clang_builder /root/clang-${CLANG_BUILD_VER} /usr
