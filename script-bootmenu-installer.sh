#!/sbin/sh

# 2nd-boot
if [ ! -d /system/bootmenu/2nd-boot ];then
  cp -R /tmp/bootmenu-installer/bootmenu/2nd-boot /system/bootmenu/2nd-boot
fi

# 2nd-init
if [ ! -d /system/bootmenu/2nd-init ];then
  cp -R /tmp/bootmenu-installer/bootmenu/2nd-init /system/bootmenu/2nd-init
fi

# moto
#if [ ! -d /system/bootmenu/moto ];then
#  cp -R /tmp/bootmenu-installer/bootmenu/moto /system/bootmenu/moto
#fi

# config
if [ ! -d /system/bootmenu/config ];then
  cp -R /tmp/bootmenu-installer/bootmenu/config /system/bootmenu/config
fi

# recovery
if [ ! -d /system/bootmenu/recovery ];then
  cp -R /tmp/bootmenu-installer/bootmenu/recovery /system/bootmenu/recovery
  
# dont replace recovery if TWRP is already installed
elif [ ! -f /system/bootmenu/recovery/sbin/teamwin ];then
  rm -Rf /system/bootmenu/recovery
  cp -R /tmp/bootmenu-installer/bootmenu/recovery /system/bootmenu/recovery
fi