#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin
source /fshook/files/_config.sh
source /fshook/files/fshook.config.sh
source $FSHOOK_PATH_RD_FILES/fshook.functions.sh
loadEnv
logi "Patching devtree..."


# remove ALL references to real nand
#logd "remove ALL references to real nand..."
#rm -f /dev/block/mmcblk1p*
#errorCheck

logd "Setting up loop-devices..."
mkdir -p $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/nand
for i in `seq 1 25`; do
  # exlude system, data and cache
  if [ $i -eq 21 ];then
    imagename=system
  elif [ $i -eq 24 ];then
    imagename=cache
  elif [ $i -eq 25 ];then
    imagename=data
  else
    imagename=nand/mmcblk1p$i
    
    # backup partition if it doesn't exists
    if [ ! -f $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/$imagename.img ];then
      logd "backup partition /dev/block/mmcblk1p$i to $FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/$imagename.img..."
	    # backup current partition
	    dd if=/dev/block/mmcblk1p$i of=$FSHOOK_PATH_MOUNT_IMAGESRC$FSHOOK_CONFIG_PATH/$imagename.img
	  fi
  fi
  
  
  # replace partition
  replacePartition /dev/block/mmcblk1p$i $imagename $(($FSHOOK_LOOPNUMBER_START+$i-1))
done

logi "Done patching devtree!"
