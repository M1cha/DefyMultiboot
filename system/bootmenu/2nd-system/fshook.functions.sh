
run_script()
{
  chmod 0755 $1
  $1
}

fshook_pathsetup()
{
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
	
  # make paths global
	setenv FSHOOK_CONFIG_PARTITION $fshook_partition
	setenv FSHOOK_CONFIG_PATH $fshook_path
}

fshook_init()
{
  # copy fshook-files to ramdisk so we can access it while system is unmounted
  mkdir -p $FSHOOK_PATH_RD_FILES
  cp -f $FSHOOK_PATH_INSTALLATION/* $FSHOOK_PATH_RD_FILES
  cp -f /system/bootmenu/script/_config.sh $FSHOOK_PATH_RD_FILES/

  # mount original data-partition
  mkdir -p $FSHOOK_PATH_MOUNT_DATA
  mount -o rw $PART_DATA $FSHOOK_PATH_MOUNT_DATA
  
  # mount original cache-partition
  mkdir -p $FSHOOK_PATH_MOUNT_CACHE
  mount -o rw $PART_CACHE $FSHOOK_PATH_MOUNT_CACHE
  
  # setup paths
  fshook_pathsetup
  
  # mount partition which contains fs-image
  mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC
  mount -o rw $FSHOOK_CONFIG_PARTITION $FSHOOK_PATH_MOUNT_IMAGESRC
}

move_system()
{
  # move original system-partition to fshook-environment
  mkdir -p $FSHOOK_PATH_MOUNT_SYSTEM
  mount -o move /system $FSHOOK_PATH_MOUNT_SYSTEM
  errorCheck
}

patch_initrc()
{
  cp -f $FSHOOK_PATH_RD_FILES/init.hook.rc /init.mapphone_umts.rc
  cat /system/bootmenu/2nd-init/init.mapphone_umts.rc >> /init.mapphone_umts.rc
  errorCheck
} 

prevent_system_unmount()
{
  cp $FSHOOK_PATH_RD_FILES/fshook.prevent_unmount.sh /system/fshook.prevent_unmount.sh
  chmod 0755 /system/fshook.prevent_unmount.sh
  /system/fshook.prevent_unmount.sh&
}

prevent_system_unmount_cleanup()
{
  rm /system/fshook.prevent_unmount.sh
}

replacePartition()
{
  PARTITION_NODE=$1
  FILENAME=$2
  LOOPID=$3
  
  losetup /dev/block/loop$LOOPID $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/$FILENAME.img
  rm -f $PARTITION_NODE
  mknod -m 0600 $PARTITION_NODE b 7 $LOOPID
  errorCheck
}

errorCheck()
{
  if [ "$?" -ne "0" ]; then
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
    echo "Error:$?"
    reboot
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
  export > $FSHOOK_PATH_RD/config.sh
}

loadEnv()
{
  # load environment vars (will be the case while re-patching devtree during boot)
  if [ -f $FSHOOK_PATH_RD/config.sh ]; then
      source $FSHOOK_PATH_RD/config.sh
  fi
}