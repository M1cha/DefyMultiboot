#!/bin/sh

# clone files into temp-dir
mkdir -p ./tmp/
cp -R ./META-INF ./tmp/
cp -R ./system ./tmp/
cp -f ./multiboot/multiboot.ko ./tmp/system/bootmenu/2nd-system/kernel-modules/

# clean files
find ./tmp/ -type f -name ".gitignore" -exec rm -f {} \;

# create zip-archive
rm -Rf ./out/*
mkdir -p ./out/
cd  ./tmp
zip -r ../out/multiboot-unsigned.zip *
cd ..

# delete temp-folder
rm -Rf ./tmp

# sign zip
java -Xmx512m -jar ./build/signapk.jar -w ./build/testkey.x509.pem ./build/testkey.pk8 ./out/multiboot-unsigned.zip ./out/multiboot.zip