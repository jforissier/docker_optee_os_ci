#!/bin/bash
#
# 1. Clone OP-TEE development environment for the specified platform
# 2. Download the cross-compile toolchain

PLAT=${1:-default}
ROOT_DIR=${2:-/root/optee}
set -e
mkdir -p ${ROOT_DIR}
cd ${ROOT_DIR}
repo init -u https://github.com/OP-TEE/manifest.git -m ${PLAT}.xml
repo sync -j20
cd ${ROOT_DIR}/build
make -j2 toolchains && rm -f ${ROOT_DIR}/toolchains/gcc*.tar.xz
