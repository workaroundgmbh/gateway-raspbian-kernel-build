.PHONY: all copy_to_sdcard clean patch release stage

ARCH := arm
CROSS_COMPILE := arm-linux-gnueabihf-
KERNEL_NAME := kernel
KERNEL_TAG := 676fd5a6f2a9b365da0e0371ef11acbb74cb69d5
KERNEL_VERSION := 4.19.126
KERNEL_FOLDER := linux-$(KERNEL_TAG)
KERNEL_ZIP := $(KERNEL_TAG).zip

PATH := $(PATH):$(shell pwd)/tools/arm-bcm2708/arm-linux-gnueabihf/bin
BOARD_CONFIG := bcmrpi_defconfig
JOBS := $(shell nproc)

BUILD ?= $(shell git describe --tags --always)
BUILD_ARTIFACT ?= gateway_kernel_$(BUILD)
BUILD_ARTIFACT_PATH ?= $(shell pwd)/build/$(BUILD_ARTIFACT)

SDCARD_MOUNT_BOOT ?= /media/${USERNAME}/boot
SDCARD_MOUNT_ROOT ?= /media/${USERNAME}/rootfs

ZIP_FILE_PREFIX=$(PWD)/$(KERNEL_NAME)-

export ARCH
export CROSS_COMPILE
export PATH


all: patch kernel

$(KERNEL_ZIP):
	wget -q https://github.com/raspberrypi/linux/archive/$(KERNEL_ZIP)

$(KERNEL_FOLDER): $(KERNEL_ZIP)
	unzip $(KERNEL_ZIP) >/dev/null

clean: $(KERNEL_FOLDER)
	make -C $(KERNEL_FOLDER) clean
	rm -rf build

kernel: $(KERNEL_FOLDER) config
	mkdir -p $(BUILD_ARTIFACT_PATH)
	make -C $(KERNEL_FOLDER) -j$(JOBS) V=0 zImage modules dtbs

patch: $(KERNEL_FOLDER)
	cd $(KERNEL_FOLDER) && for patch in $$(find ../patches/$(KERNEL_TAG) -iname '*.patch'); do \
		echo "apply patch $${patch}"; \
		patch -p1 < $$patch; \
	done

config: $(KERNEL_FOLDER) config.fragment
	make -C $(KERNEL_FOLDER) $(BOARD_CONFIG)
	cd $(KERNEL_FOLDER) && ./scripts/kconfig/merge_config.sh .config ../config.fragment

stage: $(KERNEL_FOLDER) kernel
	cp -r $(KERNEL_FOLDER)/arch/arm/boot $(BUILD_ARTIFACT_PATH)/
	INSTALL_MOD_PATH=$(BUILD_ARTIFACT_PATH) make -C $(KERNEL_FOLDER) modules_install
	rm $(BUILD_ARTIFACT_PATH)/lib/modules/*/build
	rm $(BUILD_ARTIFACT_PATH)/lib/modules/*/source

release: stage
	cp scripts/copy_to_sdcard.sh $(BUILD_ARTIFACT_PATH)/
	cd build && tar cfz $(BUILD_ARTIFACT).tgz $(BUILD_ARTIFACT)

copy_to_sdcard:
	./scripts/copy_to_sdcard.sh $(BUILD_ARTIFACT_PATH)

create_zip:
	kernel_version=$(shell make -sC $(KERNEL_FOLDER) kernelversion) && \
	./scripts/create_zip.sh $(BUILD_ARTIFACT_PATH) $(KERNEL_NAME) $(ZIP_FILE_PREFIX)$${kernel_version}.zip

push_to_cloudsmith:
	kernel_version=$(shell make -sC $(KERNEL_FOLDER) kernelversion) && \
	cloudsmith push raw proglove/gateway-cache --republish \
	$(ZIP_FILE_PREFIX)$${kernel_version}.zip \
	--version $${kernel_version} \
	--name "Linux Kernel ($(KERNEL_NAME))"
