/*
 * multiboot - adds hooks to redirect filesystem-access
 *
 * hooking taken from "n - for testing kernel function hooking" by Nothize
 * require symsearch module by Skrilaz
 *
 * Copyright (C) 2012 CyanogenDefy
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#include <linux/module.h>
#include <linux/moduleparam.h>

#include <linux/clk.h>
#include <linux/proc_fs.h>

#include <plat/clock.h>
#include <plat/clockdomain.h>
#include <plat/cpu.h>

#include <asm/uaccess.h>
#include <linux/loop.h>
#include <linux/fs.h>
#include <linux/namei.h>

#include "hook.h"

#define MODULE_TAG "multiboot"

static int hook_count = 0;
static int debug = 0;
module_param(debug, int, 0);

static bool hooked = false;

int multiboot_parse_filename(char ** name) {

    char* newname = *name;
    int ret = -1;

    // redirect NAND-partitions
    if(strcmp(*name, "/dev/block/mmcblk1p1")==0) newname = "/fshook/nodes/mmcblk1p1";
    else if(strcmp(*name, "/dev/block/mmcblk1p2")==0) newname = "/fshook/nodes/mmcblk1p2";
    else if(strcmp(*name, "/dev/block/mmcblk1p3")==0) newname = "/fshook/nodes/mmcblk1p3";
    else if(strcmp(*name, "/dev/block/mmcblk1p4")==0) newname = "/fshook/nodes/mmcblk1p4";
    else if(strcmp(*name, "/dev/block/mmcblk1p5")==0) newname = "/fshook/nodes/mmcblk1p5";
    else if(strcmp(*name, "/dev/block/mmcblk1p6")==0) newname = "/fshook/nodes/mmcblk1p6";
    else if(strcmp(*name, "/dev/block/mmcblk1p7")==0) newname = "/fshook/nodes/mmcblk1p7";
    else if(strcmp(*name, "/dev/block/mmcblk1p8")==0) newname = "/fshook/nodes/mmcblk1p8";
    else if(strcmp(*name, "/dev/block/mmcblk1p9")==0) newname = "/fshook/nodes/mmcblk1p9";
    else if(strcmp(*name, "/dev/block/mmcblk1p10")==0) newname = "/fshook/nodes/mmcblk1p10";
    else if(strcmp(*name, "/dev/block/mmcblk1p11")==0) newname = "/fshook/nodes/mmcblk1p11";
    else if(strcmp(*name, "/dev/block/mmcblk1p12")==0) newname = "/fshook/nodes/mmcblk1p12";
    else if(strcmp(*name, "/dev/block/mmcblk1p13")==0) newname = "/fshook/nodes/mmcblk1p13";
    else if(strcmp(*name, "/dev/block/mmcblk1p14")==0) newname = "/fshook/nodes/mmcblk1p14";
    else if(strcmp(*name, "/dev/block/mmcblk1p15")==0) newname = "/fshook/nodes/mmcblk1p15";
    else if(strcmp(*name, "/dev/block/mmcblk1p16")==0) newname = "/fshook/nodes/mmcblk1p16";
    else if(strcmp(*name, "/dev/block/mmcblk1p17")==0) newname = "/fshook/nodes/mmcblk1p17";
    else if(strcmp(*name, "/dev/block/mmcblk1p18")==0) newname = "/fshook/nodes/mmcblk1p18";
    else if(strcmp(*name, "/dev/block/mmcblk1p19")==0) newname = "/fshook/nodes/mmcblk1p19";
    else if(strcmp(*name, "/dev/block/mmcblk1p20")==0) newname = "/fshook/nodes/mmcblk120";
    else if(strcmp(*name, "/dev/block/mmcblk1p21")==0) newname = "/fshook/nodes/mmcblk1p21";
    else if(strcmp(*name, "/dev/block/mmcblk1p22")==0) newname = "/fshook/nodes/mmcblk1p22";
    else if(strcmp(*name, "/dev/block/mmcblk1p23")==0) newname = "/fshook/nodes/mmcblk1p23";
    else if(strcmp(*name, "/dev/block/mmcblk1p24")==0) newname = "/fshook/nodes/mmcblk1p24";
    else if(strcmp(*name, "/dev/block/mmcblk1p25")==0) newname = "/fshook/nodes/mmcblk1p25";

    // redirect partition-symlinks. It would be better to hook the function which resolves symlinks when opening a file.
    else if(strcmp(*name, "/dev/block/system")==0) newname = "/fshook/nodes/mmcblk1p21";
    else if(strcmp(*name, "/dev/block/userdata")==0) newname = "/fshook/nodes/mmcblk1p25";
    else if(strcmp(*name, "/dev/block/cache")==0) newname = "/fshook/nodes/mmcblk1p24";
    else if(strcmp(*name, "/dev/block/pkbackup")==0) newname = "/fshook/nodes/mmcblk1p23";
    else if(strcmp(*name, "/dev/block/prek")==0) newname = "/fshook/nodes/mmcblk1p22";
    else if(strcmp(*name, "/dev/block/kpanic")==0) newname = "/fshook/nodes/mmcblk1p20";
    else if(strcmp(*name, "/dev/block/cid")==0) newname = "/fshook/nodes/mmcblk1p19";
    else if(strcmp(*name, "/dev/block/misc")==0) newname = "/fshook/nodes/mmcblk1p18";
    else if(strcmp(*name, "/dev/block/cdrom")==0) newname = "/fshook/nodes/mmcblk1p17";
    else if(strcmp(*name, "/dev/block/recovery")==0) newname = "/fshook/nodes/mmcblk1p16";
    else if(strcmp(*name, "/dev/block/boot")==0) newname = "/fshook/nodes/mmcblk1p15";
    else if(strcmp(*name, "/dev/block/pds")==0) newname = "/fshook/nodes/mmcblk1p7";

    // does not work - why?
    //else if(strcmp(*name, "/data/system/batterystats.bin")==0) newname = "/fshook/mounts/data/system/batterystats.bin";
    //else if(strcmp(*name, "/data/system/batterystats.bin.tmp")==0) newname = "/fshook/mounts/data/system/batterystats.bin.tmp";

    // redirect access to ".android_secure"-folder
    /*else {
		char *needle = "/sdcard/.android_secure";
		char *replacement = "/fshook/mounts/secure/.android_secure";
		char *pch = strstr(*name, needle);
		if(pch!=NULL && (pch-*name)==0) {
			// build new name
			char buffer[strlen(replacement)+strlen(*name)-strlen(needle)];
			sprintf(buffer, "%s%.*s", replacement, strlen(*name)-strlen(needle), *name + strlen(needle));

			// copy name to pointer
			newname = kmalloc(sizeof(buffer)+1, GFP_ATOMIC);
			strcpy(newname, buffer);
			ret=0;
		}
    }*/

    if(strcmp(*name, newname)!=0)  {
    	printk("[multiboot] Redirected '%s'->'%s'\n", *name, newname);
    	kfree(*name);
    	*name = newname;
        if(ret<0) ret=1; // we want that our malloc'd pointer will be freed from outside
    } else {
    	ret = 0;
    }

    return ret;
}

/* Hooked Function */
struct file *do_filp_open(int dfd, const char *pathname,
		int open_flag, int mode, int acc_mode)
{
	//printk("[multiboot] fopen: '%s'\n", pathname);
	struct file* ret;
	char *tmp = kmalloc(strlen(pathname)+1, GFP_ATOMIC);strcpy(tmp, pathname);

	int result = multiboot_parse_filename(&tmp);
	ret = HOOK_INVOKE(do_filp_open, dfd, tmp, open_flag, mode, acc_mode);

	if(!result)kfree(tmp);
	return ret;
}

long do_mount(char *dev_name, char *dir_name, char *type_page,
		  unsigned long flags, void *data_page)
{
	printk("[multiboot] mount %s on %s type %s - flags: %ld\n", dev_name, dir_name, type_page, flags);
	long ret;
	char *tmp = kmalloc(strlen(dev_name)+1, GFP_ATOMIC);strcpy(tmp, dev_name);

	int result = multiboot_parse_filename(&tmp);
    ret = HOOK_INVOKE(do_mount, tmp, dir_name, type_page, flags, data_page);

    if(!result)kfree(tmp);
	return ret;
}

int do_vfs_ioctl(struct file *filp, unsigned int fd, unsigned int cmd,
	     unsigned long arg)
{
    int ret;

    if(cmd==LOOP_CLR_FD) {
      printk("[multiboot] Prevented clearing Loop-Device\n");
      return 0;
    }

    ret = HOOK_INVOKE(do_vfs_ioctl, filp, fd, cmd, arg);
    return ret;
}


int multiboot_user_path_at(int dfd, const char __user *name, unsigned flags,
		 struct path *path)
{
	struct nameidata nd;
	char *tmp = getname(name);

	int err = PTR_ERR(tmp);
	if (!IS_ERR(tmp)) {

		BUG_ON(flags & LOOKUP_PARENT);

		//printk("[multiboot] STAT: '%s'\n", tmp);
		int result = multiboot_parse_filename(&tmp);

		err = path_lookup(tmp, flags, &nd);
		if(!result)kfree(tmp);

		if (!err)
			*path = nd.path;
	}

	return err;
}

/*int vfs_fstatat(int dfd, char __user *filename, struct kstat *stat, int flag)
{
	struct path path;
	int error = -EINVAL;
	int lookup_flags = 0;

	if ((flag & ~AT_SYMLINK_NOFOLLOW) != 0)
		goto out;

	if (!(flag & AT_SYMLINK_NOFOLLOW))
		lookup_flags |= LOOKUP_FOLLOW;

	// not really sure if this is needed but it's more safe
	if(dfd==AT_FDCWD) {
		error = multiboot_user_path_at(dfd, filename, lookup_flags, &path);
	}
	else {
		error = user_path_at(dfd, filename, lookup_flags, &path);
	}
	if (error)
		goto out;

	error = vfs_getattr(path.mnt, path.dentry, stat);
	path_put(&path);
out:
	return error;
}*/

struct hook_info g_hi[] = {
	HOOK_INIT(do_filp_open),
	HOOK_INIT(do_mount),
	HOOK_INIT(do_vfs_ioctl),
	//HOOK_INIT(vfs_fstatat), //disabled because it's unstable and we currently don't need this
	HOOK_INIT_END
};

static int __init multiboot_init(void) {
	hook_init();
	hooked = true;

	printk("Initialized Multiboot-Module\n");
	return 0;
}

static void __exit multiboot_exit(void) {
	if (hooked) hook_exit();
	printk("Removed Multiboot-Module\n");
}

module_init(multiboot_init);
module_exit(multiboot_exit);

MODULE_ALIAS(MODULE_TAG);
MODULE_VERSION("1.0");
MODULE_DESCRIPTION("Adds hooks needed for multiboot.");
MODULE_AUTHOR("Michael Zimmermann");
MODULE_LICENSE("GPL");
