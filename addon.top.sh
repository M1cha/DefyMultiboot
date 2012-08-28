#!/sbin/sh
# 
# /system/addon.d/70-multiboot.sh
# During a CM9 upgrade, this script backs up multiboot addon,
# /system is erased and reinstalled, then this script restore a backup list.
#

. /tmp/backuptool.functions


