run_script()
{
  logd "running script $1..."
  chmod 0755 $1
  $1
}

fshook_pathsetup()
{
  logd "setup paths..."
  ### specify paths	
  # set global var for partition
  setenv FSHOOK_CONFIG_PARTITION "$MC_DEFAULT_PARTITION"
  setenv FSHOOK_CONFIG_PATH "$MC_DEFAULT_PATH"
	
  # mount partition which contains fs-image
  logd "mounting imageSrc-partition..."
  mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC
  mount -o rw $FSHOOK_CONFIG_PARTITION $FSHOOK_PATH_MOUNT_IMAGESRC
	
  # check for bypass-file
  if [ -n "$BMVAR_SYSTEMNAME" ];then
     logi "Bootmenu passed: $BMVAR_SYSTEMNAME"
     setenv FSHOOK_CONFIG_VS "$FSHOOK_CONFIG_PATH/$BMVAR_SYSTEMNAME"
     logd "virtual system: $FSHOOK_CONFIG_VS"
  else
     exit 1
  fi
  
  logd "path-setup done!"
}

fshook_init()
{
  logi "Initializing..."
  
  # mount ramdisk rw
  logd "mounting ramdisk rw..."
  mount -o remount,rw /
 
  # copy fshook-files to ramdisk so we can access them while system is unmounted
  logd "copy multiboot-files to ramdisk..."
  mkdir -p $FSHOOK_PATH_RD_FILES
  cp -Rf $FSHOOK_PATH_INSTALLATION/* $FSHOOK_PATH_RD_FILES
  cp -f /system/bootmenu/script/_config.sh $FSHOOK_PATH_RD_FILES/
  cp -f /system/bootmenu/binary/busybox $FSHOOK_PATH_RD_FILES/

  # mount original data-partition
  logd "mounting data-partition..."
  mkdir -p $FSHOOK_PATH_MOUNT_DATA
  mount -o rw $PART_DATA $FSHOOK_PATH_MOUNT_DATA
  
  # mount original cache-partition
  logd "mounting cache-partition..."
  mkdir -p $FSHOOK_PATH_MOUNT_CACHE
  mount -o rw $PART_CACHE $FSHOOK_PATH_MOUNT_CACHE
  
  # setup paths(already mounts fsimage-partition)
  fshook_pathsetup
}

checkKernel()
{
   # check if flasher is enabled
   if [ ! $MC_ENABLE_BOOTFLASHER ];then
      logi "Bootflasher is disabled!"
      return
   fi
   
   # stop here if the important files are missing
   logd "Checking for files..."
   if [ ! -f "$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/boot.img" ];then throwError;fi
   if [ ! -f "$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/devtree.img" ];then throwError;fi
   if [ ! -f "$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/logo.img" ];then throwError;fi
   
   # calculate md5sums
   logd "Calculating md5sum of boot-partition..."
   md5_nand=`md5sum /dev/block/boot | cut -d' ' -f1`
   errorCheck
   logd "Calculating md5sum of boot.img..."
   md5_virtual=`md5sum "$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/boot.img" | cut -d' ' -f1`
   errorCheck
   
   # stop here if VS's md5sum is unknown
   logd "Compare md5sum of boot.img with database..."
   if [ "$md5_virtual" != "f75ffab7f0bf66235b697ccc90db623e" -a "$md5_virtual" != "b085ebd898a3a33de3a96e0e11ac8eca" ];then
      throwError
   fi
   
   # compare md5sums
   logd "Compare boot-partition with boot.img..."
   if [ "$md5_nand" != "$md5_virtual" ];then
      logi "Flashing VS's partitions..."
      
      # flash VS's partition's
      dd if="$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/boot.img" of=/dev/block/boot
      dd if="$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/devtree.img" of=/dev/block/mmcblk1p12
      dd if="$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/logo.img" of=/dev/block/mmcblk1p10
      
      # reboot
      echo "bootvirtual:$result_name" > $FSHOOK_PATH_MOUNT_CACHE/multiboot/.bypass
      reboot
      else
	  logi "NAND already uses same partitions like VS."
      fi
}

cleanup()
{
   logd "cleanup..."
   umount $FSHOOK_PATH_MOUNT_IMAGESRC
   umount $FSHOOK_PATH_MOUNT_SYSTEM
   umount $FSHOOK_PATH_MOUNT_DATA
   umount $FSHOOK_PATH_MOUNT_CACHE
   
   if [ `busybox mount | grep -c '/fshook'` -lt 1 ];then
      rm -rf $FSHOOK_PATH_RD
   else
      throwError 1
   fi
}

move_system()
{
  logd "moving system-partition into fshook-folder..."
  # move original system-partition to fshook-environment
  mkdir -p $FSHOOK_PATH_MOUNT_SYSTEM
  mount -o move /system $FSHOOK_PATH_MOUNT_SYSTEM
  errorCheck
}

tlscheck()
{
  # multiboot not installed
  if [ "`cat /system/bootmenu/script/pre_bootmenu.sh | grep -c '\.enabletls'`" -eq 0 ];then
  
    # and tls-enabled
    if [ "`cat /system/bootmenu/script/pre_bootmenu.sh | grep -c 'tls-enable\.ko'`" -ge 1 ];then
      load_tls_module
      
    # and tls-disabled
    else
      unload_tls_module
    fi
  
  # multiboot installed and tls-enabled
  elif [ -f /system/bootmenu/config/.enabletls ];then
    load_tls_module
    
  # multiboot installed and tls-disabled
  else
    unload_tls_module
  fi
}

load_tls_module()
{
  load_symsearch
  if [ -z "`lsmod | grep tls_enable`" ]; then
    logd "Loading kernel_module: tls-enable.ko"
    insmod $FSHOOK_PATH_RD_FILES/kernel-modules/tls-enable.ko
    errorCheck
  fi
}

unload_tls_module()
{
  if [ -n "`lsmod | grep tls_enable`" ]; then
    logd "Unload kernel_module: tls-enable.ko"
    rmmod tls_enable
  fi
}

bypass_sign()
{
  logi "Setting bypass_sign to '$1'..."
  mkdir -p $FSHOOK_PATH_RD_MOUNTS/vdata
  logd "mounting virtual data partition..."
  mount $PART_DATA $FSHOOK_PATH_RD_MOUNTS/vdata
  errorCheck
  logd "creating bypass-file..."
  rm -f "$FSHOOK_PATH_RD_MOUNTS/vdata/.bootmenu_bypass"
  echo $1 > "$FSHOOK_PATH_RD_MOUNTS/vdata/.bootmenu_bypass"
  errorCheck
  logd "unmount virtual data-partition"
  umount $FSHOOK_PATH_RD_MOUNTS/vdata
  errorCheck
  logd "removing folder..."
  rm -Rf $FSHOOK_PATH_RD_MOUNTS/vdata
}

prevent_system_unmount()
{
  logd "locking unmount of system-partition..."
  cp $FSHOOK_PATH_RD_FILES/fshook.prevent_unmount.sh /system/fshook.prevent_unmount.sh
  chmod 0755 /system/fshook.prevent_unmount.sh
  /system/fshook.prevent_unmount.sh&
}

prevent_system_unmount_cleanup()
{
  logd "cleanup unmount-lock..."
  rm /system/fshook.prevent_unmount.sh
}

createLoopDevice()
{
  if [ ! -e /dev/block/loop$1 ]; then
	  # create new loop-device
    logd "Creating /dev/block/loop$1..."
	  mknod -m 0600 /dev/block/loop$1 b 7 $1
	  chown root.root /dev/block/loop$1
  fi
}

replacePartition()
{
  PARTITION_NODE="$1"
  FILENAME="$2"
  LOOPID=$3
  logd "Replacing partition $PARTITION_NODE with loop$LOOPID with image '$FILENAME'..."
  
  # setup loop-device with new image
  createLoopDevice $LOOPID
  # losetup returns 1 if filename is longer than 9 chars and losetup already done by init for some reason
  if [ "$fshookstatus" == "init" ] || [ "$fshookstatus" == "recovery" ];then
	  logd "setup loop..."
	  losetup /dev/block/loop$LOOPID "$FSHOOK_PATH_MOUNT_IMAGESRC$FILENAME"
    errorCheck
  fi
  
  # replace partition with loop-node
  logd "replace node..."
  rm -f "$PARTITION_NODE"
  mknod -m 0600 "$PARTITION_NODE" b 7 $LOOPID
  errorCheck
}

throwError()
{
    # turn off led's
    echo 0 > /sys/class/leds/red/brightness
    echo 0 > /sys/class/leds/green/brightness
    echo 0 > /sys/class/leds/blue/brightness

    # turn on red led
    echo 1 > /sys/class/leds/red/brightness

    # log error
    loge "Error: $1"
    
    # create error-log
    cp -f $logpath/multiboot.log $logpath/error.log

    # show graphical error
    $FSHOOK_PATH_RD_FILES/binary/errormessage $1
    
    # reboot and exit
    reboot
    exit $1
}

errorCheck()
{
  exitcode=$?
  if [ "$exitcode" -ne "0" ]; then
    throwError $exitcode
  fi
}

addPropVar()
{
  echo -e "\n$1=$2" >> /default.prop
}

setenv()
{
    if [ -z $3 ]; then
       export $1=$2
    else
       export $1=$3
    fi
}

saveEnv()
{
  logd "Saving environment..."
  export > $FSHOOK_PATH_RD/config.sh
}

loadEnv()
{
  # load environment vars (will be the case while re-patching devtree during boot)
  if [ -f $FSHOOK_PATH_RD/config.sh ]; then
      logd "Loading environment..."
      source $FSHOOK_PATH_RD/config.sh
  fi
}

setup_loopdevices()
{
  logi "Setting up loop-devices..."
	mkdir -p "$FSHOOK_PATH_MOUNT_IMAGESRC/$FSHOOK_CONFIG_VS/.nand"
	mkdir -p "$FSHOOK_PATH_MOUNT_IMAGESRC/$FSHOOK_CONFIG_PATH/.nand"
	mkdir -p "$FSHOOK_PATH_RD_NODES"
	for i in `seq 1 25`; do
	  # exclude system, data and cache
	  if [ $i -eq 21 ];then
	    imagename="$FSHOOK_CONFIG_VS/system.img"
	  elif [ $i -eq 24 ];then
	    imagename="$FSHOOK_CONFIG_VS/cache.img"
	  elif [ $i -eq 25 ];then
	    imagename="$FSHOOK_CONFIG_VS/data.img"
	  else
	    # backup rom-specific partitions to vs-folder
	    if [ $i -eq 15 ];then
	      imagename="$FSHOOK_CONFIG_VS/.nand/boot.img"
	    elif [ $i -eq 16 ];then
	      imagename="$FSHOOK_CONFIG_VS/.nand/recovery.img"
	    elif [ $i -eq 7 ];then
	      imagename="$FSHOOK_CONFIG_VS/.nand/pds.img"
	    elif [ $i -eq 12 ];then
	      imagename="$FSHOOK_CONFIG_VS/.nand/devtree.img"
	    elif [ $i -eq 10 ];then
	      imagename="$FSHOOK_CONFIG_VS/.nand/logo.img"
	      
	    # backup everything else into global nand-folder
	    else
	      imagename="$FSHOOK_CONFIG_PATH/.nand/mmcblk1p$i.img"
	    fi
	    
	    # backup partition if it doesn't exists
	    if [ ! -f "$FSHOOK_PATH_MOUNT_IMAGESRC$imagename" ];then
	      logd "backup partition /dev/block/mmcblk1p$i to $FSHOOK_PATH_MOUNT_IMAGESRC$imagename..."
	      # backup current partition
	      dd if=/dev/block/mmcblk1p$i of="$FSHOOK_PATH_MOUNT_IMAGESRC$imagename"
	    fi
	  fi
	  
	  # replace partition
	  replacePartition $FSHOOK_PATH_RD_NODES/mmcblk1p$i "$imagename" $(($FSHOOK_LOOPNUMBER_START+$i-1))
	done
}

load_symsearch()
{
	if [ -z "`lsmod | grep symsearch`" ]; then
  		logd "Loading kernel_module: symsearch.ko"
		insmod $FSHOOK_PATH_RD_FILES/kernel-modules/symsearch.ko
		errorCheck
	fi
}

load_kernelmodules()
{
  	logi "Loading kernel-modules..."
	load_symsearch	

	logd "Loading kernel_module: multiboot.ko"
	insmod $FSHOOK_PATH_RD_FILES/kernel-modules/multiboot.ko
	errorCheck
}

extractRamdiskFromBoot()
{
  bootimgfile="$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_VS/.nand/boot.img"
  if [ -f "$bootimgfile" ]; then
	  # unpack bootimg
	  mkdir -p "$FSHOOK_PATH_RD_TMP/unpackbootimg"
	  $FSHOOK_PATH_RD_FILES/binary/unpackbootimg -i "$bootimgfile" -o "$FSHOOK_PATH_RD_TMP/unpackbootimg"
	  
	  # extract ramdisk to root
	  cd /
	  gunzip -c "$FSHOOK_PATH_RD_TMP/unpackbootimg/boot.img-ramdisk.gz" | cpio -i -u
	  
	  # cleanup
	  rm -rf $FSHOOK_PATH_RD_TMP/unpackbootimg/*
 fi
}

getLogpath()
{
  # check for path of cache-partition
  mount | grep $FSHOOK_PATH_MOUNT_CACHE
  if [ $? -ne 0 ]; then
   logpath=/cache/multiboot
  else
   logpath=$FSHOOK_PATH_MOUNT_CACHE/multiboot
  fi
  
  # create log-folder if it does not exists
  if [ ! -d $logpath ]; then
    mkdir -p $logpath
  fi
}

initlog()
{
  getLogpath
 
  # backup old logfile if there is one
	if [ -f $logpath/multiboot.log ]; then
	   rm -f $logpath/multiboot_last.log
	   mv $logpath/multiboot.log $logpath/multiboot_last.log
	fi
	
	# create new logfile
	echo "" > $logpath/multiboot.log
}

logtofile()
{
  getLogpath
  
  # check if directory exists
	if [ -f $logpath/multiboot.log ]; then
	  # write to logfile
	  echo -e "$1/[`date`]: $2" >> $logpath/multiboot.log
	fi
}

logi()
{
 log -t MULTIBOOT -p i "$1"
 logtofile "I" "$1"
}

loge()
{
 log -t MULTIBOOT -p e "$1"
 logtofile "E" "$1"
}

logw()
{
 log -t MULTIBOOT -p w "$1"
 logtofile "W" "$1"
}

logd()
{
 log -t MULTIBOOT -p d "$1"
 logtofile "D" "$1"
}

logv()
{
 log -t MULTIBOOT -p v "$1"
 logtofile "V" "$1"
}