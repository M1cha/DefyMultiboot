#!/bin/sh

TOP_DIR=`pwd`
FOLDER="$TOP_DIR/$1"
MULTIBOOT_DIR="$TOP_DIR/$2"


getfiles() {
  for i in `ls -a $1`
  do
    if [ "$i" = "." ] || [ "$i" = ".." ];then
      continue
    fi
    echo "$1/$i"
    if [ -d "$1/$i" ];then
      getfiles "$1/$i"
    fi
  done
}

cd $FOLDER/system
mkdir -p ./addon.d/

# header
cp -f $MULTIBOOT_DIR/addon.top.sh  ./addon.d/70-multiboot.sh

# function list_files
echo "list_files() {"    >> ./addon.d/70-multiboot.sh
echo "cat <<EOF"         >> ./addon.d/70-multiboot.sh
getfiles bootmenu/2nd-system >> ./addon.d/70-multiboot.sh
getfiles bootmenu/binary >> ./addon.d/70-multiboot.sh
getfiles bootmenu/images >> ./addon.d/70-multiboot.sh
getfiles bootmenu/script >> ./addon.d/70-multiboot.sh
getfiles bin             >> ./addon.d/70-multiboot.sh
echo "bootmenu/config/multiboot_default_system.conf" >> ./addon.d/70-multiboot.sh
echo "EOF"               >> ./addon.d/70-multiboot.sh
echo "}"                 >> ./addon.d/70-multiboot.sh

# function list_files
echo "list_files_recovery() {"    >> ./addon.d/70-multiboot.sh
echo "cat <<EOF"         >> ./addon.d/70-multiboot.sh
getfiles bootmenu/recovery >> ./addon.d/70-multiboot.sh
echo "EOF"               >> ./addon.d/70-multiboot.sh
echo "}"                 >> ./addon.d/70-multiboot.sh

cat $MULTIBOOT_DIR/addon.bottom.sh >> ./addon.d/70-multiboot.sh