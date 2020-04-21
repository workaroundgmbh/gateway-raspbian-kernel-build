# Gateway Raspbian Kernel Build

Build configuration for the raspbian Linux kernel used in the Gateway project.

This contains the actual sources and tools in these submodules:

 - https://github.com/raspberrypi/linux
 - https://github.com/raspberrypi/tools

Clone with `--recursive` or use `git submodules update --init` later:

```
git clone --recurse-submodules --shallow-submodules git@github.com:workaroundgmbh/gateway-raspbian-kernel-build.git
```

## Prerequisites

On debian based sytems such as Ubuntu run:

```
sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
```

## Build Kernel

Just run the Makefile all target for a build:

```
make
```

## Release Bundles

This is mainly a preparation for eventual github/cloudsmith/etc releases:

```
make release
```

## Copy Kernel And Modules Onto SD Card

```
make copy_to_sdcard
```

For different mount points specify `SDCARD_MOUNT_BOOT=/my/path SDCARD_MOUNT_ROOT=/my/path`.

## Customization

In order to customize the built kernel these options are currently supported:

### Kernel Config

Edit [config.fragment](./config.fragment):

```
CONFIG_IN_KERNEL=y
CONFIG_AS_MODULE=m
# CONFIG_UNWANTED is not set
```

The config is merged over the original raspbian kernel config in
target `config` of the [Makefile](./Makefile).

### Kernel Patches

Add `*.patch` files in [patches](./patches) directory.

The patches are applied in listing order by the `patch` target in the [Makefile](./Makefile).
