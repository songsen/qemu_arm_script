#!/bin/bash


source env.sh

source build_busybox.sh

source build_kernel.sh

source build_uboot.sh

source run_qemu.sh



# 定义选项和参数的规则  
OPTS="hv:b:s:u:k:"  
ARGS=""  

# 解析命令行选项和参数  
while getopts "$OPTS" opt; do  
    case $opt in  
        b)  #build busybox类型
            build_busybox_type $OPTARG
        ;;
        k)  # build kernel type
            build_kernel_type $OPTARG
        ;;
        u)  # build uboot type
            build_uboot_type $OPTARG
        ;;
        s)  
            starup_type $OPTARG
        ;;
        v)  
            echo "Version: $0, OPTARG=$OPTARG"  
            exit 0  
        ;;  
        *)  
            echo "Invalid option: $opt"  
            exit 1  
        ;;  
    esac  
done  
  
# 处理剩余的命令行参数（非选项）  
shift $((OPTIND-1))  
echo "Remaining arguments: $@"
