#!/sbin/sh
######## BootMenu Script
######## Execute [Multiboot Init] Menu

export PATH=/sbin:/system/xbin:/system/bin
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh
source $BM_ROOTDIR/2nd-system/fshook.functions.sh

if [ ! -f $FSHOOK_PATH_BYPASS_CLEANUP ];then
  cleanup
fi

exit
