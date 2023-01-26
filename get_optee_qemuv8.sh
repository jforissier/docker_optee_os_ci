#!/bin/bash
#
# 1. Clone OP-TEE development environment for QEMUv8 (64-bit Arm) [1]
# 2. Download the cross-compile toolchain
#
# [1] https://optee.readthedocs.io/en/latest/building/devices/qemu.html#qemu-v8

set -e
mkdir -p /root/optee_repo_qemu_v8
cd /root/optee_repo_qemu_v8
repo init -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml
repo sync -j20
cd /root/optee_repo_qemu_v8/build
make -j2 toolchains && rm -f /root/optee_repo_qemu_v8/toolchains/gcc*.tar.xz
