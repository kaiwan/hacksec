FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI += " file://0001-am62x-harden-env-but-allow-sdmmc-boot-first-for-test.patch \
#            "
#file://0001-am62x-harden-default-env-eMMC-only-FIT-signed-boot.patch
SRC_URI += "file://hardening.cfg \
            file://0001-am62x-load-signed-FIT-from-FAT-try-SD-then-eMMC.patch \
            "
#	    file://0002-am62x-load-signed-FIT-from-FAT-try-SD-then-eMMC.patch
#            file://0001-am62x-bootcmd-env-var-to-select-sdcard-then-emmc.patch \
#            "
#            file://0001-am62x-harden-but-keep-sdmmc-boot-for-now.patch 
#            "

INSANE_SKIP:${PN} += "patch-status"

# override the default environment natively in the recipe
#do_configure:append() {
#    # This targets the default environment inside the U-Boot source config header
#    # Adjust based on whether your board configuration uses a specific header file
#    echo '#define CONFIG_EXTRA_ENV_SETTINGS "bootargs=console=ttyS2,115200n8 earlycon=ns16550a,mmio32,0x02800000 root=PARTUUID=076c4a2a-02 ro rootfstype=erofs rootwait magic_param=1\0"' >> ${S}/include/configs/am62x_evm.h
#}

do_configure:append() {
 bbplain ">>> in our u-boot bbappend"
}

