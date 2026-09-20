FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI += " file://0001-am62x-harden-env-but-allow-sdmmc-boot-first-for-test.patch \
#            "
#file://0001-am62x-harden-default-env-eMMC-only-FIT-signed-boot.patch
SRC_URI += "file://hardening.cfg \
            file://0001-am62x-bootcmd-env-var-to-select-sdcard-then-emmc.patch \
            "
#            file://0001-am62x-harden-but-keep-sdmmc-boot-for-now.patch 
#            "

INSANE_SKIP:${PN} += "patch-status"

do_configure:append() {
 bbplain ">>> in our u-boot bbappend"
}

