#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin
source /fshook/files/_config.sh
source /fshook/files/fshook.config.sh
source $FSHOOK_PATH_RD_FILES/fshook.functions.sh
loadEnv

######## NAND
# create stub image where all data will be written instead of the real nand
if [ ! -f $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/stub.img ]; then
    dd if=/dev/zero of=$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/stub.img bs=1024 count=15000
fi

# create pds image from original partition
if [ ! -f $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/pds.img ]; then
    dd if=$PART_PDS/dev/block/mmcblk1p7 of=$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/pds.img bs=4096
fi

# remove ALL references to real nand
rm -f /dev/block/mmcblk1p*
errorCheck

# setup stub-partitions
losetup /dev/block/loop3 $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/stub.img
for i in `seq 1 25`; do
  mknod -m 0600 /dev/block/mmcblk1p$i b 7 3
  errorCheck
done


######## REPLACE PARTITIONS
# system
replacePartition $PART_SYSTEM system 4
# data
replacePartition $PART_DATA data 6
# cache
replacePartition $PART_CACHE cache 5
# pds
replacePartition $PART_PDS pds 2
