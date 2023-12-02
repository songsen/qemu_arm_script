



function build_uboot_init()
{
    cd $LINUX_SOURCE_ROOT
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- vexpress_ca9x4_defconfig
}

function build_uboot()
{
    cd $UBOOT_SOURCE_ROOT
    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 
}

function test_uboot()
{
    cd $UBOOT_SOURCE_ROOT
    qemu-system-arm   -M vexpress-a9 \
                     -kernel u-boot \
                     -nographic      \
                     -m 512M          \
                     -net nic -net tap,ifname=tap0,script=no,downscript=no
                     # -netdev tap,id=nd0,ifname=tap0 -device e1000,netdev=nd0
                     # -netdev tap,id=n2 -device virtio-net,netdev=n2.
}

function build_uboot_type()
{
    case $1 in
        'init')
            echo "start building uboot..."
            build_uboot_init
            echo "uboot build done."
        ;;
        'build')
            echo "start building uboot..."
            build_uboot
            echo "uboot build done."
        ;;
        'test') 
            echo "start testing uboot..." 
            test_uboot
        ;;
        *)
            echo "nothing to do. "
        ;;
    esac
}