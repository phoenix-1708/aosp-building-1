#!/bin/bash

MANIFEST=git://github.com/crdroidandroid/android.git
BRANCH=11.0

mkdir -p /tmp/rom
cd /tmp/rom

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice. Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init --no-repo-verify --depth=1 -u "$MANIFEST" -b "$BRANCH" -g default,-device,-mips,-darwin,-notdefault

# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j30 || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j8
rm -rf .repo

# Sync device tree and stuffs
git clone https://github.com/eurekadevelopment/android_device_samsung device/Samsung
git clone https://github.com/eurekadevelopment/proprietary_vendor_samsung vendor/samsung
git clone --depth=1 https://github.com/geckyn/android_kernel_samsung_exynos7885 kernel/samsung/exynos7885
git clone https://github.com/LineageOS/android_hardware_samsung hardware/samsung

# Normal build steps
. build/envsetup.sh
lunch lineage_a10-userdebug

# upload function for uploading rom zip file! I don't want unwanted builds in my google drive haha!
up(){
	curl --upload-file $1 https://oshi.at/$(basename $1); echo
	# 14 days, 10 GB limit
}

mka bacon -j16
up out/target/product/a10/*zip
up out/target/product/a10/*json
