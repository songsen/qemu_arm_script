# script for qemu arm

qemu for arm

build uboot busybox kernel for  vexpress-a9 board

use:

```shell
# build uboot
./build_arm.sh -u init -u build
# build kernel
./build_arm.sh -k init -k build -k dtbs -k modules -k uimage
# build busybox
./build_arm.sh -b init -b build -b install -b rootfs

# boot qemu
./build_arm.sh -s zimage

```

## 网络启动

```bash

# 2. 宿主机创建tap0网卡
$ ifconfig
$ ip tuntap add dev tap0 mode tap
$ ip link set dev tap0 up
$ ip address add dev tap0 192.168.2.128/24

# 3. 虚拟机启动需要添加参数
# -net nic -net tap,ifname=tap0,script=no,downscript=no
$ qemu-system-arm -M vexpress-a9 \
-nographic      \
-m 512M          \
-kernel $UBOOT_SOURCE_ROOT/u-boot \
-net nic -net tap,ifname=tap0,script=no,downscript=no \
-append "root=/dev/mmcblk0 rw console=ttyAMA0" \
-sd $BUILD_ROOT/rootfs.ext3

#4. Uboot环境设置网络
=> setenv ipaddr 192.168.2.12           # 设置u-boot这边的地址(和br0同一网段即可)
=> setenv serverip 192.168.2.128        # 设置服务器地址(br0网桥的地址)
=> tftp 0x60003000 uImage                    # 从tftp下载uImage
=> tftp 0x60500000 vexpress-v2p-ca9.dtb   # 从tftp下载设备树
=> setenv bootargs "root=/dev/mmcblk0 rw console=ttyAMA0"    # 设置根文件系统挂载位置、权限、控制台设备
=> bootm 0x60003000 - 0x60500000    # 设置启动地址

```

## sd分区启动

SD卡分为4个分区，依次分别是boot/dtbs/kernel/rootfs四个分区。

````bash

# 制作SD卡镜像
$ dd if=/dev/zero of=fs_vexpress_1G.img bs=1M count=1024
# 查找第一个未使用的设备
$ losetup -f
# 挂载SD卡为loop设备， ~~目的是为了SD卡可以像物理磁盘一样被分区~~
$ sudo losetup /dev/loop0 fs_vexpress_1G.img
# 对SD卡进行分区
$ sudo fdisk /dev/loop15
# g 新建一份 GPT 分区表
# n 添加新分区
# x 高级设置
# n 更改分区名
# 最后分区信息如下
Disk /dev/loop15：1 GiB，1073741824 字节，2097152 个扇区
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：gpt
磁盘标识符: 750D52BA-A15A-5A4D-BE07-C20AE7A229CF
第一个 LBA: 2048
最后一个 LBA: 2097118
替代 LBA: 2097151
分区记录项 LBA: 2
已分配的分区项: 128

设备            起点    末尾    扇区 类型-UUID                            UUID                                 名称   属性
/dev/loop15p1   2048  104447  102400 0FC63DAF-8483-4772-8E79-3D69D8477DE4 95B76D16-31CE-5244-A0B1-D3DA82E01B7A uboot
/dev/loop15p2 104448  206847  102400 0FC63DAF-8483-4772-8E79-3D69D8477DE4 194BDCE1-26C7-CD47-AA26-94B26C5A3D82 dtbs
/dev/loop15p3 206848  411647  204800 0FC63DAF-8483-4772-8E79-3D69D8477DE4 0B49B892-4164-2F46-BFA7-AE27F43BAED0 kernel
/dev/loop15p4 411648 2097118 1685471 0FC63DAF-8483-4772-8E79-3D69D8477DE4 BA325D4F-BC9D-C74A-832E-B0E54086045E rootfs
# 需要执行partprobe命令才能发现新分区
$ sudo partprobe /dev/loop15

$ ls /dev/loop15p*
/dev/loop15  /dev/loop15p1  /dev/loop15p2  /dev/loop15p3  /dev/loop15p4

# 把文件系统rootfs写入p4分区
$ sudo dd if=rootfs.ext3 of=/dev/loop15p4  bs=1M count=64

# 对sd卡其它分区进行格式化
$ sudo mkfs.ext3 /dev/loop15p1
$ sudo mkfs.ext3 /dev/loop15p2
$ sudo mkfs.ext3 /dev/loop15p3

# 挂载分区
$ cd /mnt && sudo mkdir uboot dtbs rootfs kernel
$ sudo mount /dev/loop15p2 /mnt/uboot
$ sudo mount /dev/loop15p3 /mnt/dtbs
$ sudo mount /dev/loop15p4 /mnt/kernel
$ sudo mount /dev/loop15p4 /mnt/rootfs

# 拷贝镜像到分区
$ sudo cp u-boot /mnt/uboot
$ sudo cp vexpress-v2p-ca9.dtb /mnt/dtbs
$ sudo cp uImage /mnt/kernel

# 卸载分区
$ sudo umount /mnt/uboot
$ sudo umount /mnt/dtbs
$ sudo umount /mnt/rootfs
$ sudo umount /mnt/kernel
$ cd /mnt && sudo rm -rf uboot dtbs rootfs kernel

# 断开loop设备挂载
$ sudo losetup -d /dev/loop15

# qemu 启动
$ cd $UBOOT_SOURCE_ROOT
$ qemu-system-arm   -M vexpress-a9 \
-kernel u-boot \
-nographic      \
-m 512M          \
-net nic -net tap,ifname=tap0,script=no,downscript=no \
-sd $BUILD_ROOT/fs_vexpress_1G.img

# 进入uboot命令行
# SD卡启动
=> load mmc 0:3 0x60003000 uImage
5065696 bytes read in 1463 ms (3.3 MiB/s)
=> load mmc 0:2 0x60500000 vexpress-v2p-ca9.dtb
14081 bytes read in 13 ms (1 MiB/s)

=> setenv bootargs "root=/dev/mmcblk0p4 rw console=ttyAMA0"
=> bootm 0x60003000 - 0x60500000

````

uboot 指令

```bash
=> help
?         - alias for 'help'
base      - print or set address offset
bdinfo    - print Board Info structure
blkcache  - block cache diagnostics and control
bootefi   - Boots an EFI payload from memory
bootelf   - Boot from an ELF image in memory
bootflow  - Boot flows
bootm     - boot application image from memory
bootp     - boot image via network using BOOTP/TFTP protocol
bootvx    - Boot vxWorks from an ELF image
bootz     - boot Linux zImage image from memory
cmp       - memory compare
cp        - memory copy
crc32     - checksum calculation
dhcp      - boot image via network using DHCP/TFTP protocol
echo      - echo args to console
env       - environment handling commands
erase     - erase FLASH memory
exit      - exit script
ext2load  - load binary file from a Ext2 filesystem
ext2ls    - list files in a directory (default /)
ext4load  - load binary file from a Ext4 filesystem
ext4ls    - list files in a directory (default /)
ext4size  - determine a file's size
false     - do nothing, unsuccessfully
fatinfo   - print information about filesystem
fatload   - load binary file from a dos filesystem
fatls     - list files in a directory (default /)
fatmkdir  - create a directory
fatrm     - delete a file
fatsize   - determine a file's size
fatwrite  - write file into a dos filesystem
fdt       - flattened device tree utility commands
flinfo    - print FLASH memory information
fstype    - Look up a filesystem type
fstypes   - List supported filesystem types
go        - start application at address 'addr'
help      - print command description/usage
iminfo    - print header information for application image
ln        - Create a symbolic link
load      - load binary file from a filesystem
loop      - infinite loop on address range
ls        - list files in a directory (default /)
md        - memory display
mii       - MII utility commands
mm        - memory modify (auto-incrementing address)
mmc       - MMC sub system
mmcinfo   - display MMC info
mw        - memory write (fill)
net       - NET sub-system
nm        - memory modify (constant address)
panic     - Panic with optional message
part      - disk partition related commands
ping      - send ICMP ECHO_REQUEST to network host
printenv  - print environment variables
protect   - enable or disable FLASH write protection
pxe       - commands to get and boot from pxe files
random    - fill memory with random pattern
reset     - Perform RESET of the CPU
run       - run commands in an environment variable
save      - save file to a filesystem
saveenv   - save environment variables to persistent storage
setenv    - set environment variables
showvar   - print local hushshell variables
size      - determine a file's size
source    - run script from memory
sysboot   - command to get and boot from syslinux files
test      - minimal test like /bin/sh
tftpboot  - boot image via network using TFTP protocol
true      - do nothing, successfully
ubi       - ubi commands
ubifsload - load file from an UBIFS filesystem
ubifsls   - list files in a directory
ubifsmount- mount UBIFS volume
ubifsumount- unmount UBIFS volume
version   - print monitor, compiler and linker version

```
