FROM ubuntu:24.10
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y \
  autoconf \
  bc \
  bison \
  ccache \
  clang \
  cmake \
  codespell \
  curl \
  device-tree-compiler \
  expect \
  flex \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  gcc-riscv64-linux-gnu \
  gdisk \
  gettext \
  git \
  libncurses6 \
  libssl-dev \
  lld \
  llvm \
  lsb-release \
  make \
  python3 \
  python3-cryptography \
  python3-pycodestyle \
  python3-pycryptodome \
  python3-pyelftools \
  sudo \
  uuid-dev \
  vim \
  wget \
 && apt-get autoremove
