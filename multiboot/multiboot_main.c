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

#include "hook.h"

#define MODULE_TAG "multiboot"

static int hook_count = 0;
static int debug = 0;
module_param(debug, int, 0);

static bool hooked = false;

char* multiboot_parse_filename(const char* name) {
    char buffer[30];
    int i;
    char* ret = name;

    // redirect our nodes
    for(i=1; i<=25; i++) {
        // check if current device is a NAND-partition
        sprintf(buffer, "/dev/block/mmcblk1p%d", i);
        if(strcmp(name, buffer)==0) {
            // redirect to our loopdevice-nodes
            sprintf(buffer, "/fshook/nodes/mmcblk1p%d", i);
            ret = kmalloc( sizeof(buffer) + 1 , GFP_ATOMIC);
            strcpy(ret, buffer);
            break;
        }
    }

    if(strcmp(name, "/dev/block/system")==0)  {
		strcpy(ret, "/fshook/nodes/mmcblk1p21");
	}
    else if(strcmp(name, "/dev/block/userdata")==0)  {
		strcpy(ret, "/fshook/nodes/mmcblk1p25");
	}
    else if(strcmp(name, "/dev/block/cache")==0)  {
		strcpy(ret, "/fshook/nodes/mmcblk1p24");
	}
    /*else if(strcmp(name, "/data/system/batterystats.bin")==0)  {
		strcpy(ret, "/fshook/mounts/data/system/batterystats.bin");
	}
    else if(strcmp(name, "/data/system/batterystats.bin.tmp")==0)  {
		strcpy(ret, "/fshook/mounts/data/system/batterystats.bin.tmp");
	}*/

    if(strcmp(name, ret)!=0)  {
        printk("[multiboot] Redirected '%s'->'%s'\n", name, ret);
    }

    return ret;
}

/* Hooked Function */
struct file *do_filp_open(int dfd, const char *pathname,
		int open_flag, int mode, int acc_mode)
{
	pathname = multiboot_parse_filename(pathname);
	return HOOK_INVOKE(do_filp_open, dfd, pathname, open_flag, mode, acc_mode);
}

long do_mount(char *dev_name, char *dir_name, char *type_page,
		  unsigned long flags, void *data_page)
{
	printk("[multiboot] mount %s on %s type %s\n", dev_name, dir_name, type_page);
	dev_name = multiboot_parse_filename(dev_name);
    return HOOK_INVOKE(do_mount, dev_name, dir_name, type_page, flags, data_page);
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

/*int vfs_fstatat(int dfd, char __user *filename, struct kstat *stat, int flag)
{
	char *kname;
	char *old_kname;

	// copy filename to kernel-space
	kname = getname(filename);
	old_kname = kname;

	// parse filename
	kname = multiboot_parse_filename(kname);

	// copy filename back to userspace if it has changed
	if(strcmp(kname, old_kname)!=0) {
		if(copy_to_user(filename, kname, strlen(kname) + 1)!=0) {
			printk("[multiboot] FATAL: vfs_fstatat: could not write back '%s' to user-space!\n", kname);
		}
		else {
			printk("[multiboot] STAT: New filename: '%s'!\n", filename);
		}
	}

	kfree(kname);
	return HOOK_INVOKE(vfs_fstatat, dfd, filename, stat, flag);
}*/

struct hook_info g_hi[] = {
	HOOK_INIT(do_filp_open),
	HOOK_INIT(do_mount),
	HOOK_INIT(do_vfs_ioctl),
	//HOOK_INIT(vfs_fstatat),
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
