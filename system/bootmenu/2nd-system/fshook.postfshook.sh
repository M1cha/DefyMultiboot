#!/sbin/sh
export PATH=/sbin:/system/xbin:/system/bin

# mount NAND's /cache/recovery-folder into vNAND so things like reboot recovery will work
mkdir -p /cache/recovery
mount -o bind /fshook/mounts/cache/recovery /cache/recovery

