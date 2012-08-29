#!/sbin/sh
######## BootMenu Script
######## Execute [Multiboot Init] Menu

export PATH=/sbin:/system/xbin:/system/bin
source /system/bootmenu/script/_config.sh
source $BM_ROOTDIR/2nd-system/fshook.config.sh

# copy files
mkdir -p $FSHOOK_PATH_RD_FILES
cp -Rf $FSHOOK_PATH_INSTALLATION/* $FSHOOK_PATH_RD_FILES
cp -f /system/bootmenu/script/_config.sh $FSHOOK_PATH_RD_FILES/
cp -f /system/bootmenu/binary/busybox $FSHOOK_PATH_RD_FILES/

# mount imageSrc-partition
mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC
mount -o rw $MC_DEFAULT_PARTITION $FSHOOK_PATH_MOUNT_IMAGESRC

# copy bootmode.conf to NANDs cache-partition if last bootmode was multiboot
if [ "`cat /cache/bootmenu/last_bootmode`" == "2nd-system" ];then
  cacheimage="$FSHOOK_PATH_MOUNT_IMAGESRC$MC_DEFAULT_PATH/`cat /cache/bootmenu/last_mbsystem`/cache.img"
  if [ -f $cacheimage ];then
  	 # mount virtual cache-partition
     mkdir -p $FSHOOK_PATH_MOUNT_CACHE
     $BB mount -o rw $cacheimage $FSHOOK_PATH_MOUNT_CACHE
     
     if [ -f $FSHOOK_PATH_MOUNT_CACHE/recovery/bootmode.conf ];then
	bootmode=`cat $FSHOOK_PATH_MOUNT_CACHE/recovery/bootmode.conf`
	
	if [ "$bootmode" == "recovery" ];then
	  bootmode="2nd-system-recovery"
	  cat /cache/bootmenu/last_mbsystem > /cache/recovery/multiboot_bootmode.conf
	fi
	
	# write bootmode to NAND
	echo -n "$bootmode" > /cache/recovery/bootmode.conf
	
	# clear virtual bootmode
	mv $FSHOOK_PATH_MOUNT_CACHE/recovery/bootmode.conf $FSHOOK_PATH_MOUNT_CACHE/recovery/last_bootmode
     fi
	   
     # unmount virtual cache-partition
     umount $FSHOOK_PATH_MOUNT_CACHE
     
     # FIX: disassociate loop-device
     loopdevicename=`losetup | grep "$cacheimage" | cut -d':' -f0`
     if [ -n $loopdevicename ];then
	losetup -d $loopdevicename
     fi
  fi
fi

exit
