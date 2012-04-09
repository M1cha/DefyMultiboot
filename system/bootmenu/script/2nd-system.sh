#!/sbin/sh
######## BootMenu Script
######## Execute [2nd-init] Menu

export PATH=/sbin:/system/xbin:/system/bin
export fshookstatus="init"
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh
source $BM_ROOTDIR/2nd-system/fshook.functions.sh
initlog


######## FS-hook

logi "Started fshook."

# remount dev(moved from 2nd-init because at an later stage this would kill fshook)
mount -o remount,rw,relatime,mode=775,size=128k /dev

fshook_init
run_script $FSHOOK_PATH_RD_FILES/fshook.edit_devtree.sh
move_system
busybox mount -o rw $PART_SYSTEM /system

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

if [ -f /system/framework/com.motorola.android.frameworks.jar ];then
  logi "booting stock-rom..."
  source $FSHOOK_PATH_RD_FILES/fshook.bootstockrom.sh
else
  logi "booting cyanogen-rom..."
  source $FSHOOK_PATH_RD_FILES/fshook.bootcyanogenrom.sh
fi



