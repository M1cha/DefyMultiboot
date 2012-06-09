/*
 * clockfix - fixup module for Motorola Defy/Defy+
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

/* Hooked Function */
struct file *do_filp_open(int dfd, const char *pathname,
		int open_flag, int mode, int acc_mode)
{
	struct file * ret;
	struct file_with_filename *retpatched;
	char *old_pathname = pathname;
	char *arg_pathname = pathname;
	char buffer[30];
	int i;
	
	// redirect our nodes
	for(i=1; i<=25; i++) {
	    // check if current device is a NAND-partition
	    sprintf(buffer, "/dev/block/mmcblk1p%d", i);
	    if(strcmp(arg_pathname, buffer)==0) {
		// redirect to our loopdevice-nodes
		sprintf(buffer, "/fshook/nodes/mmcblk1p%d", i);
		arg_pathname=buffer;
		printk("[multiboot] Redirected '%s'->'%s'\n", old_pathname, arg_pathname);
		break;
	    }
	}
	
	// call original function
	ret = HOOK_INVOKE(do_filp_open, dfd, arg_pathname, open_flag, mode, acc_mode);
	return ret;
}

long do_mount(char *dev_name, char *dir_name, char *type_page,
		  unsigned long flags, void *data_page) {
    long ret;
    char *old_devname = dev_name;
    char *arg_devname = dev_name;
    char buffer[30];
    int i;
    
    printk("[multiboot] mount '%s' on '%s'\n", dev_name, dir_name);
    
    for(i=1; i<=25; i++) {
	// check if current device is a NAND-partition
	sprintf(buffer, "/dev/block/mmcblk1p%d", i);
	if(strcmp(arg_devname, buffer)==0) {
	    // redirect to our loopdevice-nodes
	    sprintf(buffer, "/fshook/nodes/mmcblk1p%d", i);
	    arg_devname=buffer;
	    printk("[multiboot] Redirected '%s'->'%s'\n", old_devname, arg_devname);
	    break;
	}
    }
    
    ret = HOOK_INVOKE(do_mount, arg_devname, dir_name, type_page, flags, data_page);
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

struct hook_info g_hi[] = {
	HOOK_INIT(do_filp_open),
	HOOK_INIT(do_mount),
	HOOK_INIT(do_vfs_ioctl),
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
