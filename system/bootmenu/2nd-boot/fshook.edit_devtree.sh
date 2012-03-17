#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin
source /fshook/files/fshook.functions.sh
loadEnv

######## NAND
# create stub image where all data will be written instead of the real nand
if [ ! -f /fshook/mounts/imageSrc$FSHOOK_IMAGEPATH/stub.img ]; then
    dd if=/dev/zero of=/fshook/mounts/imageSrc$FSHOOK_IMAGEPATH/stub.img bs=1024 count=15000
fi

# create pds image from original partition
if [ ! -f /fshook/mounts/imageSrc$FSHOOK_IMAGEPATH/pds.img ]; then
    dd if=/dev/block/mmcblk1p7 of=/fshook/mounts/imageSrc$FSHOOK_IMAGEPATH/pds.img bs=4096
fi

# remove ALL references to real nand
rm -f /dev/block/mmcblk1p*
errorCheck

# setup stub-partitions
losetup /dev/block/loop3 /fshook/mounts/imageSrc$FSHOOK_IMAGEPATH/stub.img
for i in `seq 1 25`; do
  mknod -m 0600 /dev/block/mmcblk1p$i b 7 3
  errorCheck
done


######## REPLACE PARTITIONS
# system
replacePartition mmcblk1p21 system 4
# data
replacePartition mmcblk1p25 data 6
# cache
replacePartition mmcblk1p24 cache 5
# pds
replacePartition mmcblk1p7 pds 2
