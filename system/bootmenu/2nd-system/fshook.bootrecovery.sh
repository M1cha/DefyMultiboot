#!/sbin/sh
######## BootMenu Script
######## Execute [Multiboot Recovery] Menu

export PATH=/sbin:/system/xbin:/system/bin
export fshookstatus="recovery"
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh
source $BM_ROOTDIR/2nd-system/fshook.functions.sh
initlog

export BMVAR_RECOVERYMODE="$1"
export BMVAR_SYSTEMNAME="$2"


######## FS-hook

logi "Started fshook - recoverymode"

# initialize environment
fshook_init

# Lib-Path for TWRP-recovery
export LD_LIBRARY_PATH=.:/sbin

# initilialize hooks
setup_loopdevices
load_kernelmodules

# switch to virtual cache-image
logd "switch to virtual cache-partition..."
umount /cache
mount -o nosuid,nodev,noatime,nodiratime,barrier=0 -t ext3 $PART_CACHE /cache


######## Main Script

## /tmp folder can be a link to /data/tmp, bad thing !
[ -L /tmp ] && rm /tmp
mkdir -p /tmp
mkdir -p /res

rm -f /etc
mkdir /etc

# hijack mke2fs & tune2fs CWM3
rm -f /sbin/mke2fs
rm -f /sbin/tune2fs
rm -f /sbin/e2fsck

rm -f /sdcard
mkdir /sdcard

chmod 755 /sbin
chmod 755 /res

cp -r -f $BM_ROOTDIR/recovery/res/* /res/
cp -p -f $BM_ROOTDIR/recovery/sbin/* /sbin/

# [fshook]patch resources
cp -r -f /system/bootmenu/2nd-system/recovery/res/* /res/
cp -p -f /system/bootmenu/2nd-system/recovery/sbin/* /sbin/

if [ ! -f /sbin/recovery_stable ]; then
    ln -s /sbin/recovery /sbin/recovery_stable
elif [ ! -f /sbin/recovery ]; then
    ln -s /sbin/recovery_stable /sbin/recovery
fi

cd /sbin
ln -s recovery edify
ln -s recovery setprop
ln -s recovery dump_image
ln -s recovery erase_image
ln -s recovery flash_image
ln -s recovery mkyaffs2image
ln -s recovery unyaffs
ln -s recovery nandroid
ln -s recovery volume
ln -s recovery reboot

chmod +rx /sbin/*

rm -f /sbin/postrecoveryboot.sh

if [ ! -e /etc/recovery.fstab ]; then
    cp $BM_ROOTDIR/recovery/recovery.fstab /etc/recovery.fstab
fi

# for ext3 format
cp $BM_ROOTDIR/config/mke2fs.conf /etc/

mkdir -p /cache/recovery
touch /cache/recovery/command
touch /cache/recovery/log
touch /cache/recovery/last_log
touch /tmp/recovery.log

killall adbd

ps | grep -v grep | grep adbd
ret=$?

if [ ! $ret -eq 0 ]; then
   # $BM_ROOTDIR/script/adbd.sh

   # don't use adbd here, will load many android process which locks /system
   killall adbd
   killall adbd.root
fi

#############################
# mount in /sbin/postrecoveryboot.sh
#umount /system
move_system

usleep 50000
mount -t $FS_SYSTEM -o rw,noatime,nodiratime $PART_SYSTEM /system

# retry without type & options if not mounted
[ ! -f /system/build.prop ] && mount -o rw $PART_SYSTEM /system

# set red led if problem with system
echo 0 > /sys/class/leds/red/brightness
echo 0 > /sys/class/leds/green/brightness
echo 0 > /sys/class/leds/blue/brightness
[ ! -f /system/build.prop ] && echo 1 > /sys/class/leds/red/brightness

#############################

# WORKAROUND: prevent unmount of system-partition
prevent_system_unmount

if [ "$BMVAR_RECOVERYMODE" == "STABLE" ];then
  /sbin/recovery_stable
elif [ "$BMVAR_RECOVERYMODE" == "CUSTOM" ];then
  /sbin/recovery
fi

# WORKAROUND: delete script
prevent_system_unmount_cleanup


# Post Recovery (back to bootmenu)

# remount system & data if unmounted
[ ! -d /data/data ] &&         mount -t $FS_DATA -o rw,noatime,nodiratime,errors=continue $PART_DATA /data
[ ! -f /system/build.prop ] && mount -t $FS_SYSTEM -o rw,noatime,nodiratime,errors=continue $PART_SYSTEM /system

if [ -f /system/build.prop ] ; then
	echo 0 > /sys/class/leds/red/brightness
	echo 0 > /sys/class/leds/green/brightness
	echo 1 > /sys/class/leds/blue/brightness
else
	echo 1 > /sys/class/leds/red/brightness
	echo 0 > /sys/class/leds/green/brightness
	echo 0 > /sys/class/leds/blue/brightness
fi

exit
