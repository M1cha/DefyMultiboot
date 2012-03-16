#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin

#### NAND
# create stub image where all data will be written instead of the real nand
if [ ! -f /fshook/mounts/imageSrc/fsimages/stub.img ]; then
    dd if=/dev/zero of=/fshook/mounts/imageSrc/fsimages/stub.img bs=1024 count=15000
fi

# create pds image from original partition
if [ ! -f /fshook/mounts/imageSrc/fsimages/pds.img ]; then
    dd if=/dev/block/mmcblk1p7 of=/fshook/mounts/imageSrc/fsimages/pds.img bs=4096
fi

# remove ALL references to real nand
rm /dev/block/mmcblk1p*

# setup stub-partitions
losetup /dev/block/loop3 /fshook/mounts/imageSrc/fsimages/stub.img
for i in `seq 1 25`; do
mknod -m 0600 /dev/block/mmcblk1p$i b 7 3
done


#### SYSTEM
# setup virtual image as device
losetup /dev/block/loop4 /fshook/mounts/imageSrc/fsimages/system.img
rm /dev/block/mmcblk1p21
mknod -m 0600 /dev/block/mmcblk1p21 b 7 4


######## DATA
# setup virtual image as device
losetup /dev/block/loop6 /fshook/mounts/imageSrc/fsimages/data.img
rm /dev/block/mmcblk1p25
mknod -m 0600 /dev/block/mmcblk1p25 b 7 6


######## CACHE
# setup virtual image as device
losetup /dev/block/loop5 /fshook/mounts/imageSrc/fsimages/cache.img
rm /dev/block/mmcblk1p24
mknod -m 0600 /dev/block/mmcblk1p24 b 7 5


######## PDS
# setup virtual image as device
losetup /dev/block/loop2 /fshook/mounts/imageSrc/fsimages/pds.img
rm /dev/block/mmcblk1p7
mknod -m 0600 /dev/block/mmcblk1p7 b 7 2
