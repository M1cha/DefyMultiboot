#!/sbin/sh
######## BootMenu Script
######## Execute [2nd-init] Menu

export PATH=/sbin:/system/xbin:/system/bin


######## FS-hook

source /system/bootmenu/2nd-system/fshook.functions.sh

# mount ramdisk rw (moved from 2nd-init)
mount -o remount,rw /

# remount dev(moved from 2nd-init because at an later stage this would kill fshook)
mount -o remount,rw,relatime,mode=775,size=128k /dev

### specify paths
# default-path
if [ -f /system/bootmenu/config/multiboot_default_system.conf ]; then
    defaultSystem=`cat /system/bootmenu/config/multiboot_default_system.conf`
else
    defaultSystem="/multiboot/default"
fi
# path from bootmenu
setenv FSHOOK_IMAGESRC /dev/block/mmcblk0p1 $1
setenv FSHOOK_IMAGEPATH $defaultSystem $2

fshook_init
run_script /fshook/files/fshook.edit_devtree.sh
move_system
busybox mount -o rw -t ext3 /dev/block/mmcblk1p21 /system
#patch_batterystats

# add props
addPropVar "ro.multiboot" "1"
addPropVar "ro.multiboot.source" "$FSHOOK_IMAGESRC"
addPropVar "ro.multiboot.path" "$FSHOOK_IMAGEPATH"

# save environment variables for later devtree-patching
saveEnv



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

