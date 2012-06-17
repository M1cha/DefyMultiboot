
multiboot_dir := external/multiboot
MULTIBOOT_VERSION := 0.6

multiboot: \
	multiboot_clean \
	multiboot_copy_to_temp \
	multiboot_copy_to_product \
	multiboot_standalone_update


multiboot_clean:
	rm -Rf $(PRODUCT_OUT)/system/bootmenu/2nd-system
	rm -Rf $(PRODUCT_OUT)/system/bootmenu/script/2nd-system.sh
	rm -Rf $(OUT_DIR)/multiboot_tmp
	rm -f $(PRODUCT_OUT)/multiboot-standalone.zip
	rm -f $(PRODUCT_OUT)/multiboot-standalone-signed.zip
	
multiboot_copy_to_temp:
	# copy files to temp-directory
	mkdir $(OUT_DIR)/multiboot_tmp
	cp -R $(multiboot_dir)/system $(OUT_DIR)/multiboot_tmp/
	
	# clean files from gitignore-files
	find $(OUT_DIR)/multiboot_tmp/ -type f -name ".gitignore" -exec rm -f {} \;
	
	# create version-file
	echo $(MULTIBOOT_VERSION) > $(OUT_DIR)/multiboot_tmp/system/bootmenu/2nd-system/.version
	
multiboot_copy_to_product:
	cp -R $(OUT_DIR)/multiboot_tmp/system $(PRODUCT_OUT)/
	
multiboot_standalone_update:
	# copy kernel-modules
	mkdir -p $(OUT_DIR)/multiboot_tmp/system/bootmenu/2nd-system/kernel-modules
	cp device/motorola/jordan/modules/symsearch/symsearch.ko $(OUT_DIR)/multiboot_tmp/system/bootmenu/2nd-system/kernel-modules/
	cp device/motorola/jordan/modules/multiboot/multiboot.ko $(OUT_DIR)/multiboot_tmp/system/bootmenu/2nd-system/kernel-modules/
	
	# copy updater-script
	cp -R $(multiboot_dir)/META-INF $(OUT_DIR)/multiboot_tmp/
	mv $(OUT_DIR)/multiboot_tmp/META-INF/com/google/android/updater-script $(OUT_DIR)/multiboot_tmp/META-INF/com/google/android/updater-script.tmp
	sed -r 's/\{VERSION\}/$(MULTIBOOT_VERSION)/' $(OUT_DIR)/multiboot_tmp/META-INF/com/google/android/updater-script.tmp > $(OUT_DIR)/multiboot_tmp/META-INF/com/google/android/updater-script
	rm $(OUT_DIR)/multiboot_tmp/META-INF/com/google/android/updater-script.tmp
	
	# build zip
	cd $(OUT_DIR)/multiboot_tmp && zip -r ../../$(PRODUCT_OUT)/multiboot-standalone.zip *
	
	# sign zip
	java -jar $(HOST_OUT_JAVA_LIBRARIES)/signapk.jar -w build/target/product/security/testkey.x509.pem build/target/product/security/testkey.pk8 $(PRODUCT_OUT)/multiboot-standalone.zip $(PRODUCT_OUT)/multiboot-standalone-signed.zip
	