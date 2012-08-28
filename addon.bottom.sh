EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
  ;;
  restore)

    # copy new files
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done

    # copy bootmenu-alias
    cp /system/bin/bootmenu /system/bootmenu/binary/bootmenu

    # create symlinks
    rm -f /system/xbin/logwrapper
    rm -f /system/bin/logwrapper
    rm -f /system/bin/lsof
    rm -f /system/bootmenu/images/indeterminate1.png
    rm -f /system/bootmenu/images/indeterminate2.png
    rm -f /system/bootmenu/images/indeterminate3.png
    rm -f /system/bootmenu/images/indeterminate4.png
    rm -f /system/bootmenu/images/indeterminate5.png
    rm -f /system/bootmenu/images/indeterminate6.png
    ln -s /system/bin/logwrapper.bin /system/xbin/logwrapper
    ln -s /system/bin/bootmenu /system/bin/logwrapper
    ln -s /system/bootmenu/binary/lsof /system/bin/lsof
    ln -s indeterminate.png /system/bootmenu/images/indeterminate1.png
    ln -s indeterminate.png /system/bootmenu/images/indeterminate2.png
    ln -s indeterminate.png /system/bootmenu/images/indeterminate3.png
    ln -s indeterminate.png /system/bootmenu/images/indeterminate4.png
    ln -s indeterminate.png /system/bootmenu/images/indeterminate5.png
    ln -s indeterminate.png /system/bootmenu/images/indeterminate6.png
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    # Stub
  ;;
esac