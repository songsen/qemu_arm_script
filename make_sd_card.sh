#!/bin/bash

function create_disk()
{
#qemu 模拟sd分区启动
    #创建ext3分区
    #创建ext3分区
    #将ext3分区写入sd卡启动
    dd if=/dev/zero of=$1.ext3 bs=1M count=$2
    mkfs.ext3 $1.ext3
}


device_name=loop15

function mount_disk()
{
    sudo losetup /dev/$device_name $BUILD_ROOT/fs_vexpress_1G.img
    sudo partprobe /dev/$device_name
}

function umount_disk()
{
    sudo losetup -d /dev/$device_name
}

function mount_partition()
{
    cd /mnt && sudo mkdir uboot dtbs rootfs kernel
    sudo mount /dev/${device_name}p1 /mnt/uboot
    sudo mount /dev/${device_name}p2 /mnt/dtbs
    sudo mount /dev/${device_name}p3 /mnt/kernel
    sudo mount /dev/${device_name}p4 /mnt/rootfs
}

function umount_partition()
{
    sudo umount /mnt/uboot
    sudo umount /mnt/dtbs
    sudo umount /mnt/rootfs
    sudo umount /mnt/kernel
    cd /mnt && sudo rm -rf uboot dtbs rootfs kernel
}


function copy_filesystem()
{
    sudo cp $UBOOT_SOURCE_ROOT/u-boot /mnt/uboot 
    sudo cp $LINUX_SOURCE_ROOT/arch/arm/boot/dts/vexpress-v2p-ca9.dtb /mnt/dtbs
    sudo cp $LINUX_SOURCE_ROOT/arch/arm/boot/uImage /mnt/kernel
}


function make_sd_card()
{
    case $1 in
        'mount')
            mount_disk
            mount_partition
            ;;
        'umount')
            umount_partition
            umount_disk
            ;;
        'copy')
            copy_filesystem
        ;;
        'all')
            create_disk $1 10
            mount_disk_init
            mount_partition
            copy_filesystem
            umount_partition
            ;;
        *)
            echo "Error: unknown type"
            exit 1
            ;;
    esac
}