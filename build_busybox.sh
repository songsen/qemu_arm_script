
function build_busybox_init()
{
    echo "make config"
    cd $BUSYBOX_SOURCE_ROOT
    #make oldconfig
    make defconfig
}

function build_busybox()
{
    cd $BUSYBOX_SOURCE_ROOT
    make  -j2 ARCH=arm  CROSS_COMPILE=arm-linux-gnueabi-
}

function install_busybox()
{
    cd $BUSYBOX_SOURCE_ROOT
    make  -j2 ARCH=arm  CROSS_COMPILE=arm-linux-gnueabi- install 
}

function generate_rcs()
{
    cd $BUILD_ROOTFS_DIR
    mkdir -p etc/init.d
    cd etc/init.d
    sudo chmod 777 ./ -R

        cat << EOF > rcS
#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin 
export LD_LIBRARY_PATH=/lib:/usr/lib
/bin/mount -n -t ramfs ramfs /var
/bin/mount -n -t ramfs ramfs /tmp
/bin/mount -n -t sysfs none /sys
/bin/mount -n -t ramfs none /dev
/bin/mkdir /var/tmp
/bin/mkdir /var/modules
/bin/mkdir /var/run
/bin/mkdir /var/log
/bin/mkdir -p /dev/pts
/bin/mkdir -p /dev/shm
/sbin/mdev -s
/bin/mount -a

ifconfig eth0 192.168.2.12
route add default gw 192.168.2.128

/usr/sbin/telnetd

/sbin/init
EOF

echo "-----------------------------------"
echo "*****welcome to vexpress board*****"
echo "-----------------------------------"
EOF
}

function generate_fstab()
{
    cd $BUILD_ROOTFS_DIR
    mkdir -p etc/sysconfig
    cd etc
    sudo chmod 777 ./ -R

    cat << EOF > fstab
proc    /proc           proc    defaults        0       0
none    /dev/pts        devpts  mode=0622       0       0
mdev    /dev            ramfs   defaults        0       0
sysfs   /sys            sysfs   defaults        0       0
tmpfs   /dev/shm        tmpfs   defaults        0       0
tmpfs   /dev            tmpfs   defaults        0       0
tmpfs   /mnt            tmpfs   defaults        0       0
var     /dev            tmpfs   defaults        0       0
ramfs   /dev            ramfs   defaults        0       0
EOF

    cat << EOF > inittab
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF

    cat << EOF > profile
USER="root"
LOGNAME=\$USER
export HOSTNAME=\`cat /etc/sysconfig/HOSTNAME\`
export USER=root
export HOME=/root
export PS1="[\$USER@\$HOSTNAME \W]\# "
PATH=/bin:/sbin:/usr/bin:/usr/sbin
LD_LIBRARY_PATH=/lib:/usr/lib:\$LD_LIBRARY_PATH
export PATH LD_LIBRARY_PATH
EOF

    cd sysconfig
    cat << EOF > HOSTNAME
vexpress
EOF
    echo "$BUILD_ROOTFS_DIR"
}



function rootfs_busybox()
{
    echo "make rootfs"
    if [ -e $BUILD_ROOTFS_DIR ];then
        sudo umount /mnt
        sudo rm -rf $BUILD_ROOTFS_DIR
    fi

    mkdir -p $BUILD_ROOTFS_DIR
    cp -r $BUSYBOX_INSTALL_DIR/* $BUILD_ROOTFS_DIR/

    cd $BUILD_ROOTFS_DIR
    sudo mkdir -p lib dev mnt proc root sys tmp var
    sudo cp -afd /usr/arm-linux-gnueabi/lib/* lib/

    cd $BUILD_ROOTFS_DIR 
    cd dev 
    sudo mknod -m 666 tty1 c 4 1
    sudo mknod -m 666 tty2 c 4 2
    sudo mknod -m 666 tty3 c 4 3
    sudo mknod -m 666 tty4 c 4 4
    sudo mknod -m 666 console c 5 1
    sudo mknod -m 666 null c 1 3

    generate_rcs
    generate_fstab

    cd $BUILD_ROOT
    dd if=/dev/zero of=rootfs.ext3 bs=1M count=64
    mkfs.ext3 rootfs.ext3
    sudo mount -t ext3 rootfs.ext3 /mnt -o loop
    sudo cp -af $BUILD_ROOTFS_DIR/* /mnt
    sudo umount /mnt

}

function build_busybox_type()
{
    case $1 in
        'init')
            echo "start building busybox..."
            build_busybox_init
            echo "busybox build done."
        ;;
        'build')
            echo "start building busybox..."
            build_busybox
            echo "busybox build done."
        ;;
        'install') 
            echo "start install busybox..." 
            install_busybox
            echo "busybox install done."
        ;;
        'rootfs') 
            echo "start install busybox..." 
            rootfs_busybox
        ;;
        *)
            echo "nothing to do. "
        ;;
    esac
}

