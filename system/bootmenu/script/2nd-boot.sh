#!/sbin/sh
######## BootMenu Script
######## Execute [2nd-init] Menu


export PATH=/sbin:/system/xbin:/system/bin

######## FS-hock

# mount ramdisk rw (moved from 2nd-init)
mount -o remount,rw /

# remount dev(moved from 2nd-init because at an later stage this would kill fshook)
mount -o remount,rw,relatime,mode=775,size=128k /dev

# initialize fshook
chmod 0755 /system/bootmenu/2nd-boot/fshook.init.sh
/system/bootmenu/2nd-boot/fshook.init.sh

# edit partition-nodes in devtree
chmod 0755 /fshook/files/fshook.edit_devtree.sh
/fshook/files/fshook.edit_devtree.sh

# move original system-partition to another location
chmod 0755 /fshook/files/fshook.move_system.sh
/fshook/files/fshook.move_system.sh

# mount virtual system-partition
busybox mount -o rw -t ext3 /dev/block/mmcblk1p21 /system



######## Main Script

rm -f /*.rc
cp -f /system/bootmenu/2nd-init/* /

# write init-hook
cp -f /fshook/files/init.hook.rc /init.mapphone_umts.rc
cat /system/bootmenu/2nd-init/init.mapphone_umts.rc >> /init.mapphone_umts.rc

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

