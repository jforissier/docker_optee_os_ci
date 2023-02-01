#!/bin/bash
#
# 1. Clone OP-TEE development environment for QEMUv8 (64-bit Arm) [1]
# 2. Download the cross-compile toolchain
#
# [1] https://optee.readthedocs.io/en/latest/building/devices/qemu.html#qemu-v8

ROOT_DIR=${1:-/root/optee_repo_qemu_v8}
set -e
mkdir -p ${ROOT_DIR}
cd ${ROOT_DIR}
repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml
repo sync -j20
cd ${ROOT_DIR}/build
make -j2 toolchains && rm -f ${ROOT_DIR}/toolchains/gcc*.tar.xz
