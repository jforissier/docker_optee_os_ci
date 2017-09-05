FROM ubuntu:17.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

RUN apt-get update \
 && apt-get install -y \
  android-tools-fastboot \
  autoconf \
  bc \
  bison \
  ccache \
  curl \
  expect \
  flex \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  gdisk \
  gettext \
  git \
  libmagickwand-dev \
  libssl-dev \
  make \
  nodejs-legacy \
  npm \
  python-crypto \
  python-pip \
  python-serial \
  python-wand \
  sudo \
  uuid-dev \
  vim \
  wget \
 && apt-get autoremove

RUN groupadd -r guest \
 && useradd -m -g guest -G sudo guest

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

USER guest

