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
