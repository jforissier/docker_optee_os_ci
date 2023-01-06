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

FROM ubuntu:22.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

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
