#!/sbin/sh
export PATH=/sbin:/system/xbin:/system/bin
source /fshook/files/_config.sh
source /fshook/files/fshook.config.sh
source $FSHOOK_PATH_RD_FILES/fshook.functions.sh

# mount NAND's /cache/recovery-folder into vNAND so things like reboot recovery will work
mkdir -p /cache/recovery
mount -o bind $FSHOOK_PATH_MOUNT_CACHE/recovery /cache/recovery

