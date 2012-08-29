#!/sbin/sh

# if multiboot is not installed...
if [ "`cat /system/bootmenu/script/pre_bootmenu.sh | grep -c '\.enabletls'`" -eq 0 ];then

  # if rom needs tls-support
  if [ "`cat /system/bootmenu/script/pre_bootmenu.sh | grep -c 'tls-enable\.ko'`" -ge 1 ];then
    touch /system/bootmenu/config/.enabletls
  fi
fi