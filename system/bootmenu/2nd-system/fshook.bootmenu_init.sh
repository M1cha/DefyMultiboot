#!/sbin/sh
######## BootMenu Script
######## Execute [Multiboot Init] Menu

export PATH=/sbin:/system/xbin:/system/bin
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh

# copy files
mkdir -p $FSHOOK_PATH_RD_FILES
cp -Rf $FSHOOK_PATH_INSTALLATION/* $FSHOOK_PATH_RD_FILES
cp -f /system/bootmenu/script/_config.sh $FSHOOK_PATH_RD_FILES/
cp -f /system/bootmenu/binary/busybox $FSHOOK_PATH_RD_FILES/

# mount imageSrc-partition
mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC
mount -o rw $MC_DEFAULT_PARTITION $FSHOOK_PATH_MOUNT_IMAGESRC

exit
