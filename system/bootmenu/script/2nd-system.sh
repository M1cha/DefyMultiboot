#!/sbin/sh
######## BootMenu Script
######## Execute [2nd-init] Menu

export PATH=/sbin:/system/xbin:/system/bin
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
saveEnv
logi "fshook-initialisation done!"



######## Main Script

rm -f /*.rc
cp -f /system/bootmenu/2nd-init/* /

ADBD_RUNNING=`ps | grep adbd | grep -v grep`
if [ -z "$ADB_RUNNING" ]; then
    rm -f /sbin/adbd.root
    rm -f /tmp/usbd_current_state
    #delete if is a symlink
    [ -L "/tmp" ] && rm -f /tmp
    mkdir -p /tmp
else
    # well, not beautiful but do the work
    # to keep current usbd state (if present)
    if [ -L "/tmp" ]; then
        mv /tmp/usbd_current_state / 2>/dev/null
        rm -f /tmp
        mkdir -p /tmp
        mv /usbd_current_state /tmp/ 2>/dev/null
    fi
fi

if [ -L /sdcard-ext ]; then
    rm /sdcard-ext
    mkdir -p /sd-ext
fi

# patch init-scripts
patch_initrc

ln -s /init /sbin/ueventd
cp -f /system/bin/adbd /sbin/adbd

# chmod 755 /*.rc
# chmod 4755 /system/bootmenu/binary/2nd-init

ADBD_RUNNING=`ps | grep adbd | grep -v grep`
if [ -z "$ADB_RUNNING" ]; then
    rm /sbin/adbd.root
fi

## unmount devices
sync
umount /acct
umount /dev/cpuctl
umount /dev/pts
umount /mnt/asec
umount /mnt/obb
umount /cache
umount /data

######## Cleanup

rm /sbin/lsof

## busybox cleanup..
for cmd in $(/sbin/busybox --list); do
  [ -L "/sbin/$cmd" ] && rm "/sbin/$cmd"
done

rm /sbin/busybox

## used for adbd shell (can be bash also)
/system/xbin/ln -s /system/xbin/busybox /sbin/sh

## reduce lcd backlight to save battery
echo 18 > /sys/class/leds/lcd-backlight/brightness

######## Let's go
/system/bootmenu/binary/2nd-init

