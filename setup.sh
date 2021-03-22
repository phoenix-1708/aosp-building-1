#!/bin/bash
##

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

sudo apt-get install bc
MANIFEST=git://github.com/StatiXOS/android_manifest.git
BRANCH=11

mkdir -p /tmp/rom
cd /tmp/rom

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice. Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init --no-repo-verify --depth=1 -u "$MANIFEST" -b "$BRANCH" -g default,-device,-mips,-darwin,-notdefault

tg_sendText "Downloading sources"

# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8

repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j30 || repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j8
rm -rf .repo

tg_sendText "Cloning repo done"

# Sync device tree and stuffs
tg_sendText "Cloning Device stuff"

git clone https://github.com/coolhotham/device_lav.git --single-branch -b arrow-11.0 device/xiaomi/lavender --depth=1
git clone https://github.com/coolhotham/vendor_lav.git --single-branch -b arrow-11.0 vendor/xiaomi/lavender --depth=1
git clone https://github.com/NotZeetaa/nexus_kernel_lavender.git -b Hmp kernel/xiaomi/lavender --depth=1

tg_sendText "Done. Cloning HALs...."

#cloning HALs
# Sync stuffs
find hardware/qcom-caf/msm8998/display hardware/qcom-caf/msm8998/audio hardware/qcom-caf/msm8998/media .repo/ -delete
git clone https://github.com/ArrowOS/android_hardware_qcom_media --single-branch -b arrow-11.0-caf-msm8998 hardware/qcom-caf/msm8998/media --depth=1
git clone https://github.com/ArrowOS/android_hardware_qcom_audio --single-branch -b arrow-11.0-caf-msm8998 hardware/qcom-caf/msm8998/audio --depth=1
git clone https://github.com/ArrowOS/android_hardware_qcom_display --single-branch -b arrow-11.0-caf-msm8998 hardware/qcom-caf/msm8998/display --depth=1
git clone https://github.com/ArrowOS/android_hardware_qcom_vr --single-branch -b arrow-11.0 hardware/qcom-caf/vr --depth=1
git clone -b lineage-18.1 https://github.com/LineageOS/android_external_ant-wireless_antradio-library external/ant-wireless/antradio-library
git clone -b arrow-11.0 https://github.com/ArrowOS/android_packages_resources_devicesettings packages/resources/devicesettings

tg_sendText "Done... Lunching"


#prebuilts/jdk/jdk9/linux-x86/bin/java -XX:+PrintFlagsFinal -version  | grep "MaxHeapSize" 
#export _JAVA_OPTIONS="-Xmx6g"
#prebuilts/jdk/jdk9/linux-x86/bin/java -XX:+PrintFlagsFinal -version  | grep "MaxHeapSize"

# upload function for uploading rom zip file! I don't want unwanted builds in my google drive haha!

up(){
	curl --upload-file $1 https://transfer.sh/ | tee download.txt
}

tg_sendText "ccache downlading"
cd /tmp
wget https://transfer.sh/OmTx4/ccache.zip
unzip ccache.zip
tar xf cr_ccache.tar.gz
find cr_ccache.tar.gz ccache.zip -delete
cd /tmp/rom
tg_sendText "ccache done"

# Normal build steps
. build/envsetup.sh
lunch statix_lavender-userdebug
export SELINUX_IGNORE_NEVERALLOWS=true
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 10G
ccache -o compression=true
ccache -z

tg_sendText "Building"
#make api-stubs-docs
#make system-api-stubs-docs
#make test-api-stubs-docs
#make hiddenapi-lists-docs
#tg_sendText "metalava done"

brunch statix_lavender-userdebug

tg_sendText "ccache"
cd /tmp

com () 
{ 
    tar --use-compress-program="pigz -k -$2 " -cf cr_$1.tar.gz $1
}

time com ccache 5 # Compression level 1, its enough
zip ccache.zip cr_ccache.tar.gz
up ccache.zip
tg_sendFile "download.txt"

up out/target/product/lavender/*.zip
tg_sendFile "download.txt"
#tg_sendFile "out/target/product/lavender/*.zip"
up out/target/product/lavender/*.json
tg_sendFile "download.txt"
tg_sendText "Build Completed"
