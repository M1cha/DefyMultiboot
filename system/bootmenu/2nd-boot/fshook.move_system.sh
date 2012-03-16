#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin


# move original system-partition to another location
mkdir -p /fshook/mounts/system
mount -o move /system /fshook/mounts/system
