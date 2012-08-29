#!/sbin/sh
######## BootMenu Script
######## Execute [2nd-system] Menu

export PATH=/sbin:/system/xbin:/system/bin
export fshookstatus="init"
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh
source $BM_ROOTDIR/2nd-system/fshook.functions.sh
initlog

export BMVAR_SYSTEMNAME="$1"


######## FS-hook

logi "Started fshook."

# remount dev(moved from 2nd-init because at an later stage this would kill fshook)
mount -o remount,rw,relatime,mode=775,size=128k /dev

# initialize environment
fshook_init

# initilialize hooks
setup_loopdevices
load_kernelmodules

# switch to virual system-partition
move_system
busybox mount -o rw $PART_SYSTEM /system

# enable tls if new system-partition needs it
tlscheck

# setting bypass-signs
bypass_sign "yes"
touch $FSHOOK_PATH_BYPASS_CLEANUP

# add props
addPropVar "ro.multiboot" "1"
addPropVar "ro.multiboot.partition" "$FSHOOK_CONFIG_PARTITION"
addPropVar "ro.multiboot.path" "$FSHOOK_CONFIG_PATH"
addPropVar "ro.multiboot.vs" "$FSHOOK_CONFIG_VS"

# save environment variables for later devtree-patching
export fshookstatus="boot"
saveEnv
logi "fshook-initialisation done!"

######## start initialisation-script
logi "booting cyanogen-rom..."
source $FSHOOK_PATH_RD_FILES/fshook.bootcyanogenrom.sh



