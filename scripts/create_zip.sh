#! /usr/bin/env bash

set -e

SCRIPT_FOLDER=$(cd "$(dirname "$0")" && pwd)
BUILD_FOLDER=$(mktemp -d)


main() {
	local linux_build_folder="$1"
	local linux_kernel_name="$2"
	local zip_file_output_path="$3"

	if [[ -z "${linux_build_folder}" ]]; then
		echo >&2 "No Linux kernel build folder specified"
		return 1
	fi

	if [[ -z "${linux_kernel_name}" ]]; then
		echo >&2 "No Linux kernel name specified"
		return 1
	fi

	if [[ -z "${zip_file_output_path}" ]]; then
		echo >&2 "No ZIP output file specified"
		return 1
	fi

	echo "Linux build folder: ${linux_build_folder}"
	echo "Kernel name: ${linux_kernel_name}"

	mkdir -p "${BUILD_FOLDER}"/boot
	mkdir -p "${BUILD_FOLDER}"/boot/overlays
	mkdir -p "${BUILD_FOLDER}"/lib

	echo "Copy lib folder"
	cp -r --no-dereference "${linux_build_folder}"/lib/* "${BUILD_FOLDER}"/lib/

	echo "Copy zImage"
	cp "${linux_build_folder}"/boot/zImage "${BUILD_FOLDER}"/boot/"${linux_kernel_name}".img
	echo "Copy overlays"
	cp "${linux_build_folder}"/boot/dts/*-rpi-*.dtb "${BUILD_FOLDER}"/boot/
	cp "${linux_build_folder}"/boot/dts/overlays/*.dtb* "${BUILD_FOLDER}"/boot/overlays/

	rm -f "${zip_file_output_path}"
	pushd "${BUILD_FOLDER}" >/dev/null
	zip -r "${zip_file_output_path}" . >/dev/null
	echo "Zip file: $(basename "${zip_file_output_path}")"
	popd >/dev/null
}


atexit() {
	if [[ -n "${BUILD_FOLDER}" ]]; then
		rm -r "${BUILD_FOLDER}"
	fi
}


trap atexit EXIT
main "$@"
