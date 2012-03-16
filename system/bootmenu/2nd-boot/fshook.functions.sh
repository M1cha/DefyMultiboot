
run_script()
{
  chmod 0755 $1
  $1
}

fshook_parseargs()
{
  if [ -z $1 ]; then
    echo "1"

  else
    echo "2"
  fi
}

fshook_init()
{
  # copy fshook-files to ramdisk so we can access it while system is unmounted
  mkdir -p /fshook/files
  cp -f /system/bootmenu/2nd-boot/* /fshook/files

  # mount partition which contains fs-image
  mkdir -p /fshook/mounts/imageSrc
  mount -o rw $FSHOOK_IMAGESRC /fshook/mounts/imageSrc

  # mount original data-partition
  mkdir -p /fshook/mounts/data
  mount -o rw /dev/block/mmcblk1p25 /fshook/mounts/data
}

move_system()
{
  # move original system-partition to fshook-environment
  mkdir -p /fshook/mounts/system
  mount -o move /system /fshook/mounts/system
  errorCheck
}

patch_initrc()
{
  cp -f /fshook/files/init.hook.rc /init.mapphone_umts.rc
  cat /system/bootmenu/2nd-init/init.mapphone_umts.rc >> /init.mapphone_umts.rc
  errorCheck
} 

prevent_system_unmount()
{
  cp /fshook/files/fshook.prevent_unmount.sh /system/fshook.prevent_unmount.sh
  chmod 0755 /system/fshook.prevent_unmount.sh
  /system/fshook.prevent_unmount.sh&
}

prevent_system_unmount_cleanup()
{
  rm /system/fshook.prevent_unmount.sh
}

# does not work
patch_batterystats()
{
  # mount vdata
  mkdir -p /fshook/mounts/vdata
  mount -o rw /dev/block/mmcblk1p25 /fshook/mounts/vdata

  # replace batterystats
  rm /fshook/mounts/vdata/system/batterystats.bin
  ln -s /fshook/mounts/data/system/batterystats.bin /fshook/mounts/vdata/system/batterystats.bin

  # unmount vdata
  umount /fshook/mounts/vdata
  rm -R /fshook/mounts/vdata
}

replacePartition()
{
  PARTITION_NAME=$1
  IMAGE_NAME=$2
  LOOPID=$3
  
  losetup /dev/block/loop$LOOPID /fshook/mounts/imageSrc/fsimages/$IMAGE_NAME.img
  rm -f /dev/block/$PARTITION_NAME
  mknod -m 0600 /dev/block/$PARTITION_NAME b 7 $LOOPID
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
    reboot
  fi
}

addPropVar()
{
  echo -e "\n$1=$2" >> /default.prop
}