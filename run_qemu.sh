#!/bin/bash


source env.sh

function boot_zimage()
{
    qemu-system-arm -M vexpress-a9 \
                    -m 512M \
                    -kernel $LINUX_SOURCE_ROOT/arch/arm/boot/zImage \
                    -dtb $LINUX_SOURCE_ROOT/arch/arm/boot/dts/vexpress-v2p-ca9.dtb \
                    -nographic \
                    -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
                    -sd $BUILD_ROOT/rootfs.ext3
}

function boot_tftp()
{
     qemu-system-arm -M vexpress-a9 \
                     -nographic      \
                     -m 512M          \
                     -kernel $UBOOT_SOURCE_ROOT/u-boot \
                     -net nic -net tap,ifname=tap0,script=no,downscript=no \
                     -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
                     -sd $BUILD_ROOT/rootfs.ext3
    # qemu-system-arm                 \
    #     -M vexpress-a9          \
    #     -kernel ./u-boot        \
    #     -nographic              \
    #     -m 512M                 \
    #     -nic tap,ifname=tap0    \
    #     -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
    #     -sd  rootfs.ext3
}

function starup_type()
{
    case $1 in
        'tftp')
            echo "start tftp busybox..."
            boot_tftp
        ;;
        'zimage')
            echo "start zimage ..."
            boot_zimage
        ;;
        *)
            echo "nothing to do. "
        ;;
    esac
}