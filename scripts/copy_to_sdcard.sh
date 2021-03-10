#!/bin/sh
set -e

SDCARD_MOUNT_BOOT=${SDCARD_MOUNT_BOOT:-/media/$USERNAME/boot}
SDCARD_MOUNT_ROOT=${SDCARD_MOUNT_ROOT:-/media/$USERNAME/rootfs}
STAGE=${1:-.}

cp -v $STAGE/boot/zImage ${SDCARD_MOUNT_BOOT}/${KERNEL}.img
cp -v $STAGE/boot/dts/*.dtb ${SDCARD_MOUNT_BOOT}/
cp -v $STAGE/boot/dts/overlays/*.dtb* ${SDCARD_MOUNT_BOOT}/overlays/
cd $STAGE && sudo cp -v -r --no-dereference lib ${SDCARD_MOUNT_ROOT}/
