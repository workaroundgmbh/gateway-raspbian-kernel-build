.PHONY: all copy_to_sdcard clean patch release stage

ARCH := arm
CROSS_COMPILE := arm-linux-gnueabihf-
KERNEL := kernel
KERNEL_TAG := 676fd5a6f2a9b365da0e0371ef11acbb74cb69d5
PATH := $(PATH):$(shell pwd)/tools/arm-bcm2708/arm-linux-gnueabihf/bin
BOARD_CONFIG := bcmrpi_defconfig
JOBS := 4

BUILD ?= $(shell git describe --tags --always)
BUILD_ARTIFACT ?= gateway_kernel_${BUILD}
BUILD_ARTIFACT_PATH ?= $(shell pwd)/build/${BUILD_ARTIFACT}

SDCARD_MOUNT_BOOT ?= /media/${USERNAME}/boot
SDCARD_MOUNT_ROOT ?= /media/${USERNAME}/rootfs

export ARCH
export CROSS_COMPILE
export PATH

all: patch kernel

clean:
	make -C linux clean
	rm -rf build

kernel: config
	mkdir -p ${BUILD_ARTIFACT_PATH}
	make -C linux -j$(JOBS) zImage modules dtbs

patch:
	cd linux && \
	git fetch --all --tags && \
	git reset --hard $(KERNEL_TAG)

	cd linux && for patch in $$(find ../patches/$(KERNEL) -iname '*.patch'); do \
		echo "apply patch $${patch}"; \
		git apply < $$patch; \
	done

config: config.fragment
	make -C linux $(BOARD_CONFIG)
	cd linux && ./scripts/kconfig/merge_config.sh .config ../config.fragment

stage: kernel
	cp -r linux/arch/arm/boot ${BUILD_ARTIFACT_PATH}/
	INSTALL_MOD_PATH=${BUILD_ARTIFACT_PATH} make -C linux modules_install
	rm ${BUILD_ARTIFACT_PATH}/lib/modules/*/build
	rm ${BUILD_ARTIFACT_PATH}/lib/modules/*/source

release: stage
	cp scripts/copy_to_sdcard.sh ${BUILD_ARTIFACT_PATH}/
	cd build && tar cfz ${BUILD_ARTIFACT}.tgz ${BUILD_ARTIFACT}

copy_to_sdcard:
	./scripts/copy_to_sdcard.sh ${BUILD_ARTIFACT_PATH}
