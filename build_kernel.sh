



function build_kernel_init()
{
    cd $LINUX_SOURCE_ROOT
    make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm vexpress_defconfig -j2
}

function build_kernel()
{
    cd $LINUX_SOURCE_ROOT
    make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2
}

function build_dtb()
{
    cd $LINUX_SOURCE_ROOT
    make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 dtbs
}

function build_modules()
{
    cd $LINUX_SOURCE_ROOT
    make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 modules
}

function build_uimage()
{
    echo "build_uimage"
    cd $LINUX_SOURCE_ROOT
    make CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm -j2 LOADADDR=0x60003000 uImage
}

function build_kernel_type()
{
    case $1 in
        'init')
            echo "init building kernel..."
            build_kernel_init
        ;;
        'build')
            echo "start building kernel..."
            build_kernel
            echo "kernel build done."
        ;;
        'dtbs') 
            echo "make dtbs..." 
            build_dtb
            echo "make dtbs done."
        ;;
        'modules') 
            echo "make modules..." 
            build_modules
            echo "make modules done."
        ;;
        'uimage') 
            echo "make uimage ..." 
            build_uimage
            echo "make uimage done."
        ;;
        '*') 
            echo "start install kernel..." 
    esac
}