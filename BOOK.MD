# Linux内核开发提纲

## 1. 概述

本文以模拟开发板[vexpress-a9](https://www.qemu.org/docs/master/system/arm/vexpress.html)为例，主要介绍：

- 搭建开发环境
- 编译uboot 内核 busybox 制作rootfs
- 启动方式 qemu直接启动，uboot启动
- 启动时候的内存布局
- PCI设备驱动
- USB设备驱动

## 2. QEMU ARM环境搭建

开发板[vexpress-a9](https://www.qemu.org/docs/master/system/arm/vexpress.html) Arm Versatile Express boards

### 2.1 搭建开发环境

```bash
# 安装qemu
sudo apt-get install qemu-system-arm
# 下载编译器
sudo apt-get install gcc-arm-linux-gnueabi
# 下载kernel uboot busybox源码
# 准备工作目录
```

### 2.2 qemu简介

QEMU全虚拟化 （客户机不知道自己是虚拟机）和半虚拟化概念（需要安装virtio客户机知道自己是虚拟机）

```bash
qemu-system-arm -M help # 查看支持的板子
qemu-system-arm -M <board> -device pcie-root-port,? # 查看设备支持的扩展选项
```

#### 2.2.2 启动参数解释

- -m 内存大小
- -M 机器类型，[**必须选项**]
- -kernel 内核镜像，[**必须选项 uboot或者kernel**]
- -append 启动参数，传递给start_kernel的参数, 可以由uboot bootargs传递
- -nographic 不显示图形界面
- -serial stdio 串口
- -monitor stdio 监视器
- -d int 调试级别
- -cpu 指令集
- -sd sd卡
- -hda hda设备
- -dtb 可以放到sd卡里
- -netnic-nettap,ifname=tap0,script=no,downscript=no 添加网络设备

#### 2.2.3 配置虚拟设备

- -nic
- -dev
- -netdev
- -device
- -pci

### 2.2 宿主机网络配置

#### 2.2.1 桥接

#### 2.2.2 与主机共享

## 3. 编译

### 3.1 编译uboot

#### uboot的环境变量printenv

#### 设置uboot的环境变量bootargs setenv

#### 把默认环境变量写入代码

#### 切换SD卡不同的bank做系统冗余备份

#### 从不同分区加载镜像

### 3.2 编译内核

#### 3.2.1 make编译参数

````bash
# 启动UI配置内核
make menuconfig
# 加载默认值
make defconfig
# 备份当前配置,  将会生成 .config.old配置文件
make oldconfig
# 编译
make -jN

# 编译vexpress_a9
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm vexpress_defconfig -j2
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 dtbs
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 modules
make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 LOADADDR=0x60003000 uImage
````

#### 3.2.2 配置内核

可以在 arch/arm/configs/vexpress_defconfig 中配置
比如：我需要打开pci, 通过make menuconfig搜索/PCI信息可以看到打开PCI的前置条件

![1701773333691](image/Linux内核开发提纲/1701773333691.png)
那么我可以把需要的条件写入arch/arm/configs/vexpress_defconfig配置中

````bash
CONFIG_PCI=y
CONFIG_PCI_VERSATILE=y
CONFIG_SCSI=y
CONFIG_SCSI_SYM53C8XX_2=y
````

### 3.3 编译busybox

制作启动的rootfs

### 3.4 lds连接脚本解析

lds是编译后的产物，由lds.S生成，可查看生成物的编译器连接的section信息

````bash
# 'SECTIONS'是一个功能很强大的命令. 下面是一个实现这个功能的脚本:
SECTIONS #关键字'SECTIONS'写了这个SECTIONS命令,后面跟有一串放在花括号中的符号赋值和输出节描述的内容
{ 
    . = 0x10000;
    .text : { *(.text) }
    . = 0x8000000;
    .data : { *(.data) }
    .bss : { *(.bss) }
}
#上例中, 在'SECTIONS'命令中的第一行是对一个特殊的符号'.'赋值, 这是一个定位计数器. 如果你没有以其它的方式指定输出节的地址(其他方式在后面会描述), 那地址值就会被设为定位计数器的现有值. 定位计数器然后被加上输出节的尺寸. 在'SECTIONS'命令的开始处, 定位计数器拥有值'0'.
#第二行定义一个输出节,'.text'. 冒号是语法需要,现在可以被忽略. 节名后面的花括号中,你列出所有应当被放入到这个输出节中的输入节的名字. '*'是一个通配符,匹配任何文件名. 表达式'*(.text)'意思是所有的输入文件中的'.text'输入节.
#因为当输出节'.text'定义的时候, 定位计数器的值是'0x10000',连接器会把输出文件中的'.text'节的地址设为'0x10000'.
#余下的内容定义了输出文件中的'.data'节和'.bss'节. 连接器会把'.data'输出节放到地址'0x8000000'处. 连接器放好'.data'输出节之后, 定位计数器的值是'0x8000000'加上'.data'输出节的长度. 得到的结果是连接器会把'.bss'输出节放到紧接'.data'节后面的位置.
#连接器会通过在必要时增加定位计数器的值来保证每一个输出节具有它所需的对齐. 在这个例子中, 为'.text'和'.data'节指定的地址会满足对齐约束, 但是连接器可能会需要在'.data'和'.bss'节之间创建一个小的缺口.

````

### 3.5 ELF文件解析

elf是Linux/Unix系统的

```bash
readelf -a vmlinux
readelf -a zimage
readelf -a uImage
```

### 3.6 dts文件解析

设备树文件解读

### 3.7 map文件解析

生成物符号连接和地址信息

## 4. 启动

### 4.1 启动镜像分析

- vmlinux镜像构成：未压缩的镜像，x86和arm的vmlinux镜像段落布局不一样，arm的其实是压缩过后再加上头部解压代码之后的可执行镜像（因此用readeaf看不到虚拟地址），x86的其实是未压缩的镜像可以readeaf查看kernel入口的虚拟地址
- zimage镜像构成： 压缩之后加上了头部解压代码的镜像，头部解压代码与地址无关，可以加载都任意地方运行
- uImage镜像构成：uboot启动镜像，在uboot中，可以直接加载uImage镜像，也可以通过tftp网络加载uImage镜像

### 4.2 启动时的内存分析

1. 加载地址（LOADDDR）:一般在内存起始地址加上一个0x8000的偏移，内存地址再dts中定义
2. 入口地址(ZTEXTADDR)：入口地址偏移0x40
3. 内核运行地址(ZREALADDR): 解压出的地址在makefile种定义
   以上3种类型的地址可以在kernel源码种搜索（zreladdr-y）start_kernel函数的地址

uboot内存地址一部分与位置无关，一部分会被加载到编译时候就已经分配好的位置。

1. 位置无关的代码，加载业务代码到指定的内存地址

kernel内存地址一部分与位置无关，一部分会被加载到指定的位置。

1. zimage解压image到临时内存，
2. 再拷贝重定位代码到image后边，
3. 重定位代码再拷贝image到制定的入口地址

### 4.3 启动方式

#### 4.3.1 zimage直接启动镜像

可直接由qemu启动，可由uboot的bootz指令启动

#### 4.3.2 uboot加载uimage启动

uboot tftp网络加载uimage

````bash
# 
# 宿主机配置tap网络
# qemu -net nic -net tap,ifname=tap0,script=no,downscript=no -m 128M -kernel uImage -append "root=/dev/sda1 console=ttyAMA0" -hda rootfs.img
````

uboot flash加载uimage

````bash
# 制作分区SD卡，分区依次为 uboot dtbs kernel rootfs
load mmc 0:1 ${loadaddr} uImage
load mmc 0:1 ${fdtaddr} dtbs
load mmc 0:1 ${kerneladdr} kernel
load mmc 0:1 ${ramdiskaddr} rootfs.img
bootm ${loadaddr} - ${fdtaddr}
````

## 5 PCIE

### 5.1 PCIE概述

PCIE按照功能划分，[[[[`<domain>`]:]`<bus>`]:][`<slot>`][.[`<func>`]]，bus总线，slot插槽（设备），func功能（一般为0，但是一个设备上可能有多个功能比如网卡，存储器，网卡等），domain是PCIe域一般为0，一般来说，总线号和插槽号都是从0开始，可以结合lspci命令查看,需要结合PCIE物理连接拓扑图看才能明白这么表示一个PCIe设备背后的知识

````bash
lspci # 查看PCIe设备
setpci # 设置PCIe设备
lspci -k # 查看PCIe设备详细信息
lspci -v # 查看PCIe设备详细信息
lspci -s # 查看PCIe设备详细信息
lspci -s 00:00.0 # 查看PCIe设备详细信息
lspci -s 00:00.0 -vvv # 查看PCIe设备详细信息
### PCIe设备的配置空间
lspci -s 00:00.0 -vvv # 查看PCIe设备详细信息
````

### 5.2 PCIe配置空间

### 5.3 PCIE枚举

### 5.4 PCIE中断

### 5.5 PCIE驱动

## 6.  USB

## 7. 文件系统VFS

## 8. 内存管理

## 9. 调度系统

## 10. 中断系统

## 11. 性能调优

### perf工具简介

### 分析定位

## 12 debug



## 13. 附

## 9. 构建文件系统

### 9.1 busybox

### 9.2 buildroot

### 9.3 yocto

## 14. 参考资料

- [Arm Versatile boards (versatileab, versatilepb)](https://www.qemu.org/docs/master/system/arm/versatile.html)
- [Arm Versatile boards (versatileab, versatilepb)](https://www.qemu.org/docs/master/system/arm/vexpress.html)
- [Markdown 官方教程](https://markdown.com.cn/basic-syntax/links.html)
