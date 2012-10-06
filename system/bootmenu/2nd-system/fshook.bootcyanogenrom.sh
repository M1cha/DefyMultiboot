
######## Main Script

#extractRamdiskFromBoot
mount -o remount,rw /
rm -f /*.rc
cp -r -f /system/bootmenu/2nd-init/* /
chmod 755 /*.rc
chmod 4755 $FSHOOK_PATH_RD_FILES/binary/2nd-init
ln -s /init /sbin/ueventd

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

## unmount devices
sync
umount /acct
umount /mnt/asec
umount /dev/cpuctl
umount /dev/pts
umount /mnt/obb
umount /cache
umount /data

######## Cleanup

# original /tmp data symlink
if [ -L /tmp.bak ]; then
  rm /tmp.bak
fi

rm -f /sbin/lsof

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
$FSHOOK_PATH_RD_FILES/binary/2nd-init
