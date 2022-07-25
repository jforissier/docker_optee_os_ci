FROM ubuntu as clang-downloader
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

RUN apt update && \
    apt install -y wget xz-utils

ADD get_clang.sh /root/get_clang.sh
WORKDIR /root
RUN ./get_clang.sh 12.0.0 ./clang

FROM ubuntu:22.04
MAINTAINER Jerome Forissier <jerome.forissier@linaro.org>

COPY --from=clang-downloader /root/clang/ /usr/local/

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y \
  autoconf \
  bc \
  bison \
  ccache \
  clang \
  codespell \
  curl \
  device-tree-compiler \
  expect \
  flex \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  gdisk \
  gettext \
  git \
  libncurses5 \
  libssl-dev \
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

