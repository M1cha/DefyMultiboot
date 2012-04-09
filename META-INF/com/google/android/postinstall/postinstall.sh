#!/sbin/sh

# check for 2ndsystem-support
if [ `busybox strings /system/bin/bootmenu | busybox grep -ci '\[2nd-system\]'` -lt 1 ];then
  supports_2ndsystem=false
else
  supports_2ndsystem=true
fi

# check for _config.sh
if [ ! -f /system/bootmenu/script/_config.sh ]; then
  cp -f /tmp/postinstall/_config.sh /system/bootmenu/script/_config.sh
  chmod 0755 /system/bootmenu/script/_config.sh
fi

# install 2nd-boot softlink
if [ $supports_2ndsystem == false ];then
  rm -f /system/bootmenu/script/2nd-boot.sh
  ln -s 2nd-system.sh /system/bootmenu/script/2nd-boot.sh
fi

# check for multiboot-config
if [ ! -f /system/bootmenu/config/multiboot.conf ];then
  cp -f /tmp/postinstall/multiboot.conf /system/bootmenu/config/multiboot.conf
fi

# set default-bootmode
if [ $supports_2ndsystem == true ];then
 echo "2nd-system" > /system/bootmenu/config/default_bootmode.conf
else
 echo "2nd-boot" > /system/bootmenu/config/default_bootmode.conf
fi