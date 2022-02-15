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

FROM ubuntu:21.04
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
 && mkdir -p /root/optee_repo_qemu_v8 \
 && cd /root/optee_repo_qemu_v8 \
 && repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml \
 && repo sync -j20 \
 && cd /root/optee_repo_qemu_v8/build \
 && make -j2 toolchains \
 && rm -f toolchains/gcc*.tar.xz \
 && make -j$(nproc) XEN_BOOT=y \
 && rm -rf out-br out-br-domu \
 && make -j$(nproc) OPTEE_RUST_ENABLE=y optee-rust \
 && /usr/bin/bash -c "source /root/.cargo/env && make -j$(nproc) OPTEE_RUST_ENABLE=y" \
 && rm -rf out-br \
 && make arm-tf-clean \
 && make -j$(nproc)
