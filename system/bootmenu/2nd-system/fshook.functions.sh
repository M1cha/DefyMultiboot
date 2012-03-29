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
  # hardcoded paths(as internal default)
  fshook_partition=$MULTIBOOT_DEFAULT_PARTITION
  fshook_path=$MULTIBOOT_DEFAULT_PATH

  # default-path from config
	if [ -f $FSHOOK_PATH_CONFIG_DEFAULTPATH ]; then
	  # get values
		config=`cat $FSHOOK_PATH_CONFIG_DEFAULTPATH`   
		config_partition=`echo $config |cut -d':' -f1`
		config_path=`echo $config |cut -d':' -f2`
		
		# set partition
		if [ ! -z $config_partition ]; then
      fshook_partition=$config_partition
    fi
    
    # set path
    if [ ! -z $config_path ]; then
      fshook_path=$config_path
    fi
	fi
	
	# set global var for partition
	setenv FSHOOK_CONFIG_PARTITION $fshook_partition
	setenv FSHOOK_CONFIG_PATH $fshook_path
	
	# mount partition which contains fs-image
  logd "mounting imageSrc-partition..."
  mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC
  mount -o rw $FSHOOK_CONFIG_PARTITION $FSHOOK_PATH_MOUNT_IMAGESRC
	
	# generate args for GUI
  logd "search for virtual systems..."
	args=""
	for file in $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/*; do
	  if [ -d $file ]; then
	    logd "found $file!"
	    name=`basename $file`
	    args="$args$name "
	  fi
	done
	
	# get fshook_folder from GUI
  logi "starting GUI..."
	result=`/system/bootmenu/binary/multiboot $args`
	logd "GUI returned: $result"
	logd "parsing results of GUI..."
	result_mode=`echo $result |cut -d' ' -f1`
  result_name=`echo $result |cut -d' ' -f2`
  
  # set 2nd argument as fshook_folder
  if [ -n $result_name ]; then
    fshook_folder=$result_name
    
    # set global var for path to virtual system
    setenv FSHOOK_CONFIG_VS "$fshook_path/$fshook_folder"
  
    logd "virtual system: $FSHOOK_CONFIG_VS"
  fi
  
  logd "path-setup done!"
}

fshook_init()
{
  logi "Initializing..."
  
  # mount ramdisk rw
  logd "mounting ramdisk rw..."
  mount -o remount,rw /
 
  # copy fshook-files to ramdisk so we can access it while system is unmounted
  logd "copy multiboot-files to ramdisk..."
  mkdir -p $FSHOOK_PATH_RD_FILES
  cp -f $FSHOOK_PATH_INSTALLATION/* $FSHOOK_PATH_RD_FILES
  cp -f /system/bootmenu/script/_config.sh $FSHOOK_PATH_RD_FILES/

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
  bootmode=$result_mode
  logi "bootmode: $bootmode"
  
  # parse bootmode
  if [ "$bootmode" = "bootvirtual" ];then
   logi "Booting virtual system..."
  elif [ "$bootmode" = "bootnand" ];then
   logi "Booting from NAND..."
   logd "undo changes..."
   umount $FSHOOK_PATH_MOUNT_IMAGESRC
   errorCheck
   umount $FSHOOK_PATH_MOUNT_CACHE
   errorCheck
   umount $FSHOOK_PATH_MOUNT_DATA
   errorCheck
   rm -rf $FSHOOK_PATH_RD
   
   logd "run 2nd-init..."
   $BM_ROOTDIR/script/2nd-init.sh
   exit $?
  elif [ "$bootmode" = "recovery" ];then
   logi "Booting recovery for virtual system..."
   source $FSHOOK_PATH_RD_FILES/fshook.bootrecovery.sh
   exit 1
  else
   throwError
  fi
}

move_system()
{
  logd "moving system-partition into fshook-folder"
  # move original system-partition to fshook-environment
  mkdir -p $FSHOOK_PATH_MOUNT_SYSTEM
  mount -o move /system $FSHOOK_PATH_MOUNT_SYSTEM
  errorCheck
}

patch_initrc()
{
  logd "patching init.rc..."
  cp -f $FSHOOK_PATH_RD_FILES/init.hook.rc /init.mapphone_umts.rc
  cat /system/bootmenu/2nd-init/init.mapphone_umts.rc >> /init.mapphone_umts.rc
  errorCheck
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
  if [ ! -f /dev/block/loop$1 ]; then
	  # create new loop-device
	  mknod -m 0600 /dev/block/loop$1 b 7 $1
	  chown root.root /dev/block/loop$1
  fi
}

replacePartition()
{
  PARTITION_NODE=$1
  FILENAME=$2
  LOOPID=$3
  logd "Replacing partition $PARTITION_NODE with loop$LOOPID with image '$FILENAME'..."
  
  # setup loop-device with new image
  createLoopDevice $LOOPID
  losetup /dev/block/loop$LOOPID $FSHOOK_PATH_MOUNT_IMAGESRC/$FILENAME
  errorCheck
  
  # replace partition with loop-node
  rm -f $PARTITION_NODE
  mknod -m 0600 $PARTITION_NODE b 7 $LOOPID
  errorCheck
}

throwError()
{
    # turn off led's
    echo 0 > /sys/class/leds/red/brightness
    echo 0 > /sys/class/leds/green/brightness
    echo 0 > /sys/class/leds/blue/brightness

    # let red led blink two times
    echo 1 > /sys/class/leds/red/brightness
    sleep 1
    echo 0 > /sys/class/leds/red/brightness
    sleep 1
    echo 1 > /sys/class/leds/red/brightness
    sleep 1
    echo 0 > /sys/class/leds/red/brightness

    # reboot
    loge "Error: $1"
    reboot
}

errorCheck()
{
  if [ "$?" -ne "0" ]; then
    throwError $?
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