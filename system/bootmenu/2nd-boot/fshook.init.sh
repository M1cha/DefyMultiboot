#!/sbin/sh

######## initialize fshook-environement

export PATH=/sbin:/system/xbin:/system/bin

# copy fshook-files to ramdisk so we can access it while system is unmounted
mkdir -p /fshook/files
cp -f /system/bootmenu/2nd-boot/* /fshook/files

# mount partition which contains fs-image
mkdir -p /fshook/mounts/imageSrc
mount -o rw -t vfat /dev/block/mmcblk0p1 /fshook/mounts/imageSrc

exit
