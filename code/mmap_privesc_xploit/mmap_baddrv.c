/*
 * mmap_baddrv.c
 *
 * Ref and Credits:
 * https://labs.mwrinfosecurity.com/assets/BlogFiles/mwri-mmap-exploitation-whitepaper-2017-09-18.pdf
 *
 * Simple demo char device driver for memory device. Registers itself as a 'misc'
 * driver.. Here, the feature is the buggy! 'mmap' implementation.
 * This lack of valdity checking (by default, unless we pass module param 'check=1'),
 * is the root cause of the exploit being possible.
 * Of course, this exploit will easily be defeated by even minimal 'hardening':
 * proper permissions on the device file (like 0664), presence of LSMs (like
 * SELinux/AppArmor/etc), etc.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/miscdevice.h>
#include <linux/sched.h>	/* current, jiffies */
#include <linux/fs.h>		/* no_llseek */
#include <linux/version.h>      /* ver macros */
#include <linux/slab.h>		/* kmalloc */
#include <linux/mm.h>           /* remap_pfn_range */

#define	DRVNAME		"mmap_baddrv"
#define DEVICE_FILE	"/dev/mmap_baddrv"

static int check;
module_param(check, int, 0640);
MODULE_PARM_DESC(check, "1 => perform validity checks prior to mapping [default=0]");

static int mmap_bad(struct file *filp, struct vm_area_struct *vma)
{
	unsigned long int len=vma->vm_end - vma->vm_start, status=0;

	/* vm_pgoff: info about backing store, specifically, the offset 
	 * (within vm_file) in PAGE_SIZE units.
	 */
	pr_info("vma: start=0x%pK end=0x%pK len=%lu pgoff=%lu\n", 
		(void *)vma->vm_start, (void *)vma->vm_end, len, vma->vm_pgoff);

	/*
	 * The validity checks below are ESSENTIAL to the correct secure working
	 * of the driver; we deliberately turn them off here ... 'check' is a
	 * parameter to this kernel module; is zero by default; can change it by
	 * passing check=1 .
	 */
	if (check == 1) {
#define MAX_MMAP_PAGES 30 	// unit: pages
		/* Validity check: there is a hard limit (our own define, MAX_MMAP_OFFSET) 
		 * pages that the userspace app can mmap.
		 */
		if (len > (MAX_MMAP_PAGES*PAGE_SIZE)) {
			pr_notice("%s: mmap length too large! (artificial max of %d pages here)\n",
				DRVNAME, MAX_MMAP_PAGES);
			status = -EINVAL;
			goto out;
		}
		/* Validity check: don't let the app try to mmap beyond the to-be-allocated size.
		   vm_pgoff: offset (within vm_file) in PAGE_SIZE units, *not* PAGE_CACHE_SIZE */
		if ((vma->vm_pgoff*PAGE_SIZE) > len) {
			pr_notice("%s: offset too large!\n", DRVNAME);
			status = -EINVAL;
			goto out;
		}
	}

	/*
	int remap_pfn_range(struct vm_area_struct *, unsigned long addr,
                        unsigned long pfn, unsigned long size, pgprot_t);
 	 * remap_pfn_range - remap kernel memory to userspace
	 * @vma: user vma to map to
	 * @addr: target user address to start at
	 * @pfn: physical address of kernel memory
	 * @size: size of map area
	 * @prot: page protection flags for this mapping
	 */
	if ((status = remap_pfn_range(
		vma,
		vma->vm_start,
		vma->vm_pgoff, // is 0 (check w/ MMAP_MIN_ADDR [?])
		vma->vm_end - vma->vm_start, 
		vma->vm_page_prot) < 0)) {
			pr_warn("remap_pfn_range failed!\n");
			goto out;
	}
out:
	return status;
}

/* Minor-specific open routines */
static struct file_operations mmap_baddrv_fops = {
	.llseek =	no_llseek,
	.mmap   =       mmap_bad,
};

static struct miscdevice mmap_baddrv_miscdev = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "mmap_baddrv",
	.fops = &mmap_baddrv_fops,
};

static int __init mmap_baddrv_init_module(void)
{
	int ret = 0;
	pr_info("%s: initializing ... validity checking is %s\n",
		DRVNAME, check == 1?"ON":"OFF");

	/* Register the device with the kernel;s 'misc' framework */
	ret = misc_register(&mmap_baddrv_miscdev);
	if (ret != 0) {
		pr_err("could not register the misc device mydev");
		return ret;
	}
	pr_info("%s: got minor %d\n", DRVNAME, mmap_baddrv_miscdev.minor);
	return 0;
}

static void __exit mmap_baddrv_cleanup_module(void)
{
	/* Unregister the device with the kernel */
	misc_deregister(&mmap_baddrv_miscdev);
	pr_info("%s: unloaded.\n", DRVNAME);
}

module_init(mmap_baddrv_init_module);
module_exit(mmap_baddrv_cleanup_module);

MODULE_AUTHOR("Kaiwan NB");
MODULE_DESCRIPTION("Simple mmap kernel exploit demo; not mine, credits above");
MODULE_LICENSE("Dual MIT/GPL");
