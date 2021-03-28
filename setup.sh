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

#compress to tar code
com () 
{ 
    tar --use-compress-program="pigz -k -$2 " -cf cr_$1.tar.gz $1
}

# upload function for uploading rom zip file! I don't want unwanted builds in my google drive haha!
up(){
	curl --upload-file $1 https://transfer.sh/ | tee download.txt
}

sudo apt-get update -y
sudo apt-get install -y openjdk-11-jdk
java -version
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
sudo apt-get install wget
MANIFEST=git://github.com/TenX-OS/manifest_TenX
BRANCH=eleven

mkdir -p /tmp/rom
cd /tmp/rom

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice. Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init -u "$MANIFEST" -b "$BRANCH" -g default,-device,-mips,-darwin,-notdefault

tg_sendText "Downloading sources"

# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8

repo sync -c -j30 --force-sync --no-clone-bundle --no-tags || repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
rm -rf .repo

# Sync device tree and stuffs
tg_sendText "Repo done... Cloning Device stuff"

git clone https://gitlab.com/makaramhk/device_xiaomeme_lavender.git --single-branch -b tenx device/xiaomi/lavender --depth=1
git clone https://gitlab.com/randomscape/vendor_xiaomeme_lavender.git --single-branch -b arrow-11.0 vendor/xiaomi/lavender --depth=1
git clone https://github.com/NotZeetaa/nexus_kernel_lavender.git -b Hmp kernel/xiaomi/lavender --depth=1

tg_sendText "Done... Lunching"


#prebuilts/jdk/jdk9/linux-x86/bin/java -XX:+PrintFlagsFinal -version  | grep "MaxHeapSize" 
#export _JAVA_OPTIONS="-Xmx6g"
#prebuilts/jdk/jdk9/linux-x86/bin/java -XX:+PrintFlagsFinal -version  | grep "MaxHeapSize"



tg_sendText "ccache downlading"
cd /tmp
wget https://transfer.sh/KE7UK/cr_ccache.tar.gz
tar xf cr_ccache.tar.gz
find cr_ccache.tar.gz -delete
cd /tmp/rom
tg_sendText "ccache done"

# Normal build steps
export SELINUX_IGNORE_NEVERALLOWS=true
. build/envsetup.sh
lunch aosp_lavender-userdebug
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 10G
ccache -o compression=true
ccache -z

#tg_sendText "Building"
#make SystemUI
#make api-stubs-docs
#make system-api-stubs-docs
#make test-api-stubs-docs
#make hiddenapi-lists-docs
#tg_sendText "metalava done.. Building"

make bacon -j$(nproc --all) || make bacon -j16


tg_sendText "Build zip"
cd /tmp/rom
up out/target/product/lavender/*.zip
tg_sendFile "download.txt"
#tg_sendFile "out/target/product/lavender/*.zip"
tg_sendText "json"
up out/target/product/lavender/*.json
tg_sendFile "download.txt"

tg_sendText "ccache upload"
cd /tmp
time com ccache 3 # Compression level 1, its enough
up cr_ccache.tar.gz
tg_sendFile "download.txt"
cd /tmp/rom
