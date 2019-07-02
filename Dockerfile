FROM ubuntu:18.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y \
  android-tools-fastboot \
  autoconf \
  bc \
  bison \
  ccache \
  clang \
  curl \
  expect \
  flex \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  gdisk \
  gettext \
  git \
  libssl-dev \
  lsb-release \
  make \
  python-crypto \
  python-pyelftools \
  sudo \
  uuid-dev \
  vim \
  wget \
 && apt-get autoremove

