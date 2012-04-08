#!/sbin/sh

# parse bootmenu-version
version_string=$(expr "`strings /system/bin/bootmenu | grep -i 'Android Bootmenu <.*>'`" : ".*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*")
version_major=`echo "$version_string" | cut -d '.' -f1`
version_minor=`echo "$version_string" | cut -d '.' -f2`
version_patch=`echo "$version_string" | cut -d '.' -f3`

# check for 2ndsystem-support
supports_2ndsystem=false
if [ $version_major -le 1 ];then
  if [ $version_minor -le 1 ];then
    if [ $version_patch -lt 8 ];then
      supports_2ndsystem=true
    fi
  fi
fi

# check for _config.sh
if [ ! -f /system/bootmenu/script/_config.sh ]; then
  cp -f /tmp/postinstall/_config.sh /system/bootmenu/script/_config.sh
  chmod 0755 /system/bootmenu/script/_config.sh
fi

# install 2nd-boot softlink
if [ $supports_2ndsystem ];then
  rm -f /system/bootmenu/script/2nd-boot.sh
  ln -s 2nd-system.sh /system/bootmenu/script/2nd-boot.sh
fi

# check for multiboot-config
if [ ! -f /system/bootmenu/config/multiboot.conf ];then
  cp -f /tmp/postinstall/multiboot.conf /system/bootmenu/config/multiboot.conf
fi

# set default-bootmode
if [ $supports_2ndsystem ];then
 echo "2nd-system" > /system/bootmenu/config/default_bootmode.conf
else
 echo "2nd-boot" > /system/bootmenu/config/default_bootmode.conf
fi