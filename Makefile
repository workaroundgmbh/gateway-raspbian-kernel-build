.PHONY: all patch release

ARCH := arm
CROSS_COMPILE := arm-linux-gnueabihf-
KERNEL := linux
PATH := $(PATH):$(shell pwd)/tools/arm-bcm2708/arm-linux-gnueabihf/bin

BUILD ?= $(shell git describe --tags --always)
BUILD_ARTIFACT ?= gateway_kernel_${BUILD}
BUILD_ARTIFACT_PATH ?= $(shell pwd)/build/${BUILD_ARTIFACT}

SDCARD_MOUNT_BOOT ?= /media/${USERNAME}/boot
SDCARD_MOUNT_ROOT ?= /media/${USERNAME}/rootfs

export ARCH
export CROSS_COMPILE
export KERNEL
export PATH

all: patch kernel

kernel: config
	mkdir -p ${BUILD_ARTIFACT_PATH}
	make -C linux -j4 zImage modules dtbs
	INSTALL_MOD_PATH=${BUILD_ARTIFACT_PATH} make -C linux modules_install

patch:
	cd linux && git reset --hard
	cd linux && for patch in `ls ../patches/*.patch`; do \
		git apply < $$patch; \
	done

config: linux/.config config.fragment
	make -C linux bcmrpi_defconfig
	cd linux && ./scripts/kconfig/merge_config.sh .config ../config.fragment

release: #kernel
	cp -r linux/arch/arm/boot ${BUILD_ARTIFACT_PATH}/
	cd build && tar cfz ${BUILD_ARTIFACT}.tgz ${BUILD_ARTIFACT}

copy_to_sdcard:
	cp linux/arch/arm/boot/zImage ${SDCARD_MOUNT_BOOT}/kernel.img
	cp linux/arch/arm/boot/dts/*.dtb ${SDCARD_MOUNT_BOOT}/
	cp linux/arch/arm/boot/dts/overlays/*.dtb* ${SDCARD_MOUNT_BOOT}/overlays/
	cd linux/arch/arm/boot/modules && sudo cp -r * ${SDCARD_MOUNT_ROOT}/
