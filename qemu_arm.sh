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
# 前置条件
# 1. 需要在宿主机建立tap0网路
#	 ip tuntap add dev tap0 mode tap
#	 ip link set dev tap0 up
#    ip address add dev tap0 192.168.2.128/24
# 1. 需要配置宿主机的tftp服务，将dtbs和uImage放到tftp目录下，然后启动qemu
# 2. 需要在uboot命令行下载dtbs和uImage 
# 3. 需要手动启动
#	 setenv ipaddr 192.168.2.12           # 设置u-boot这边的地址(和br0同一网段即可)
#	 setenv serverip 192.168.2.128        # 设置服务器地址(br0网桥的地址)
#	 tftp 0x60003000 uImage                    # 从tftp下载uImage
#    tftp 0x60500000 vexpress-v2p-ca9.dtb   # 从tftp下载设备树
#    setenv bootargs "root=/dev/mmcblk0 rw console=ttyAMA0"  # 设置根文件系统挂载位置、权限、控制台设备
#    bootm 0x60003000 - 0x60500000    # 设置启动地址

#   启动参数
     qemu-system-arm -M vexpress-a9 \
                     -nographic      \
                     -m 512M          \
                     -kernel $UBOOT_SOURCE_ROOT/u-boot \
                     -net nic -net tap,ifname=tap0,script=no,downscript=no \
                     -append "root=/dev/mmcblk0 rw console=ttyAMA0" \
                     -sd $BUILD_ROOT/rootfs.ext3
}

function boot_sd()
{
# 前置条件
# 1. 需要模拟一张SD卡,分四个区，依次是 boot dtbs kernel rootfs, 分别放入相应的固件
# 2. uboot阶段手动加载
# 	=> load mmc 0:3 0x60003000 uImage
#	=> load mmc 0:2 0x60500000 vexpress-v2p-ca9.dtb	
#	=> setenv bootargs "root=/dev/mmcblk0p4 rw console=ttyAMA0"
#   => bootm 0x60003000 - 0x60500000
    qemu-system-arm  -M vexpress-a9 \
                     -nographic      \
                     -m 512M          \
                     -kernel $UBOOT_SOURCE_ROOT/u-boot \
                     -sd $BUILD_ROOT/fs_vexpress_1G.img
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
        'sd')
            boot_sd
        ;;
        *)
            echo "nothing to do. "
        ;;
    esac
}