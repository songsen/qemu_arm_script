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

```bash


	# 2. 宿主机创建tap0网卡
	ifconfig

	ip tuntap add dev tap0 mode tap
	ip link set dev tap0 up
	ip address add dev tap0 192.168.2.128/24

	ifconfig

	# 3. 虚拟机启动参数
	-net nic -net tap,ifname=tap0,script=no,downscript=no


	#4. Uboot设置网络
	setenv ipaddr 192.168.2.12           # 设置u-boot这边的地址(和br0同一网段即可)
	setenv serverip 192.168.2.128        # 设置服务器地址(br0网桥的地址)
	tftp 0x60003000 uImage                    # 从tftp下载uImage
	tftp 0x60500000 vexpress-v2p-ca9.dtb   # 从tftp下载设备树
	setenv bootargs "root=/dev/mmcblk0 rw console=ttyAMA0"    # 设置根文件系统挂载位置、权限、控制台设备
	bootm 0x60003000 - 0x60500000    # 设置启动地址




```
