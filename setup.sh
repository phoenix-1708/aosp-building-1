#!/bin/bash

export CHAT_ID=-1001165568594
export BOT_TOKEN=1769103266:AAHFb2yG3S3I5vspEQFtuTP-SvM1E0bjOfc
function tg_sendText() {
curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d "parse_mode=html" \
-d text="${1}" \
-d chat_id=$CHAT_ID \
-d "disable_web_page_preview=true"
}

function tg_sendFile() {
curl -F chat_id=$CHAT_ID -F document=@${1} -F parse_mode=markdown https://api.telegram.org/bot$BOT_TOKEN/sendDocument
}

MANIFEST=git://github.com/crdroidandroid/android.git
BRANCH=11.0

mkdir -p /tmp/rom
cd /tmp/rom

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice. Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init --no-repo-verify --depth=1 -u "$MANIFEST" -b "$BRANCH" -g default,-device,-mips,-darwin,-notdefault

tg_sendText "Downloading sources"
# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8
repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j30 || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j8
rm -rf .repo

# Sync device tree and stuffs
git clone https://github.com/Gabriel260/android_device_samsung_a10-common -b crdroid-arm32 device/samsung
git clone https://github.com/Gabriel260/proprietary_vendor_samsung_a10-common -b lineage-18.1-arm32 vendor/samsung
git clone --depth=1 https://github.com/geckyn/android_kernel_samsung_exynos7885 kernel/samsung/exynos7885
git clone https://github.com/Gabriel260/android_hardware_samsung-2 hardware/samsung

# Normal build steps
. build/envsetup.sh
export USE_CCACHE=0
lunch lineage_a10-userdebug

# upload function for uploading rom zip file! I don't want unwanted builds in my google drive haha!
up(){
	curl --upload-file $1 https://transfer.sh/ | tee download.txt
}
tg_sendText "Building"
mka api-stubs-docs
mka system-api-stubs-docs
mka test-api-stubs-docs
mka bacon -j16
up out/target/product/a10/*.zip
tg_sendText "download.txt"
up out/target/product/a10/*.json
tg_sendText "download.txt"

