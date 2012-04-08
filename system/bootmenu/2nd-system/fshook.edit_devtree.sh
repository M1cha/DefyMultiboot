#!/sbin/sh
######## FsHook Script
######## Replace Partitions with images for multiboot


export PATH=/sbin:/system/xbin:/system/bin
source /fshook/files/_config.sh
source /fshook/files/fshook.config.sh
source $FSHOOK_PATH_RD_FILES/fshook.functions.sh
loadEnv
logi "Patching devtree..."

logd "Setting up loop-devices..."
mkdir -p "$FSHOOK_PATH_MOUNT_IMAGESRC/$FSHOOK_CONFIG_VS/.nand"
mkdir -p "$FSHOOK_PATH_MOUNT_IMAGESRC/$FSHOOK_CONFIG_PATH/.nand"
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
  replacePartition /dev/block/mmcblk1p$i "$imagename" $(($FSHOOK_LOOPNUMBER_START+$i-1))
done

logi "Done patching devtree!"
