
# PATH's
FSHOOK_PATH_RD="/fshook"
FSHOOK_PATH_INSTALLATION="/system/bootmenu/2nd-system"
FSHOOK_PATH_RD_FILES="$FSHOOK_PATH_RD/files"
FSHOOK_PATH_RD_MOUNTS="$FSHOOK_PATH_RD/mounts"
FSHOOK_PATH_RD_NODES="$FSHOOK_PATH_RD/nodes"
FSHOOK_PATH_RD_TMP="$FSHOOK_PATH_RD/tmp"

FSHOOK_PATH_CONFIG_DEFAULTPATH="$BM_ROOTDIR/config/multiboot_defaultpath.conf"
FSHOOK_PATH_CONFIG_TEMPDEFAULTPATH="$FSHOOK_PATH_RD_MOUNTS/cache/recovery/multiboot_system.conf"
FSHOOK_PATH_BYPASS_CLEANUP="$FSHOOK_PATH_RD/.dont_cleanup"

FSHOOK_PATH_MOUNT_SYSTEM="$FSHOOK_PATH_RD_MOUNTS/system"
FSHOOK_PATH_MOUNT_DATA="$FSHOOK_PATH_RD_MOUNTS/data"
FSHOOK_PATH_MOUNT_CACHE="$FSHOOK_PATH_RD_MOUNTS/cache"
FSHOOK_PATH_MOUNT_IMAGESRC="$FSHOOK_PATH_RD_MOUNTS/imageSrc"

# different things
FSHOOK_LOOPNUMBER_START=8

# default-config for multiboot
MC_ENABLE_BOOTFLASHER=false
MC_DEFAULT_PARTITION="/dev/block/mmcblk0p1"
MC_DEFAULT_PATH="/multiboot"

# load external config
if [ -f $FSHOOK_PATH_RD_MOUNTS/$BM_ROOTDIR/config/multiboot.conf ]; then
  source $FSHOOK_PATH_RD_MOUNTS/$BM_ROOTDIR/config/multiboot.conf
elif [ -f $BM_ROOTDIR/config/multiboot.conf -a "$fshookstatus" == "init" ]; then
  source $BM_ROOTDIR/config/multiboot.conf
fi