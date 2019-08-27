#!/bin/bash
#
# Copyright (c) 2019 by Delphix. All rights reserved.
#

set -xe

KERNEL_SRC=/src/linux
KERNEL_OBJ=/src/linux

# Checkout ZFS source
function get_zfs_source() {
    if [ ! -d /src/zfs ]; then
        git clone https://github.com/zfsonlinux/zfs.git /src/zfs
        cd /src/zfs
        [ -z $ZFS_VERSION ] && ZFS_VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)
        git checkout $ZFS_VERSION
    fi
}

# Get linuxkit-specific source
function get_linuxkit_kernel() {
    local kernel_version=$1
    local kernel_release=$2
    local container_id=$(docker run -d linuxkit/kernel:$kernel_version /bin/true 2>/dev/null || /bin/true)
    if [ -z $container_id ]; then
        echo "failed to launch linuxkit/kernel:$kernel_version container"
        exit 1
    fi
    cd /
    docker cp $container_id:kernel-dev.tar .
    docker cp $container_id:kernel.tar .
    tar xf kernel-dev.tar
    tar xf kernel.tar

    cd /src
    docker cp $container_id:linux.tar.xz .
    tar xf linux.tar.xz

    docker rm $container_id

    KERNEL_SRC=/src/linux
    KERNEL_OBJ=/lib/modules/$kernel_release/build
}

#
# Get ubuntu-specific modules. With Ubuntu, we can get the pre-built modules and
# headers for a given kernel release, so that we don't need to actually build from source.
#
function get_ubuntu_kernel() {
    local kernel_version=$1
    local kernel_release=$2

    apt-get update
    apt-get install -y linux-modules-$kernel_release linux-headers-$kernel_release linux-source-$kernel_version
    cd /usr/src && tar -xjf linux-source-$kernel_version.tar.bz2

    KERNEL_SRC=/usr/src/linux-source-$kernel_version
    KERNEL_OBJ=/lib/modules/$kernel_release/build
}

# Get vanilla kernel source
function get_vanilla_src() {
    local version=$1

    # Download Kernel source
    if [ ! -d /src/linux ]; then
        curl --retry 5 -o /src/linux-$version.tar.xz -L https://www.kernel.org/pub/linux/kernel/v${version%%.*}.x/linux-$version.tar.xz
        cd /src
        tar xf linux-$version.tar.xz
        mv $linux-version linux
        rm linux-$version.tar.xz
    fi
}

# Get kernel source via distro-specific mechanism, falling back to vanilla kernel.org
function get_kernel() {
    [ -z "$KERNEL_RELEASE" ] && KERNEL_RELEASE=$(uname -r)
    [ -z "$KERNEL_UNAME" ] && KERNEL_UNAME=$(uname -a)
    local kernel_version=${KERNEL_RELEASE%%-*}
    local kernel_variant=${KERNEL_RELEASE#*-}

    case $kernel_variant in
    linuxkit)
        get_linuxkit_kernel $kernel_version $KERNEL_RELEASE
        ;;
    *)
        case $KERNEL_UNAME in
        *Ubuntu*)
            get_ubuntu_kernel $kernel_version $KERNEL_RELEASE
            ;;
        *)
            get_vanilla_src $kernel_version
            build_kernel
            ;;
        esac
    esac
}

#
# Build the kernel from source. We need to do a full build because in order to build the ZFS
# kernel modules, we not only depend on specific artifacts created in that process
# (such as utsrelease.h), but we have to link against objects and we don't have
# those objects available within the builder image.
#
function build_kernel() {
    # Set kernel configuration
    if [ ! -f /src/linux/.config ]; then
        if [ -f /config/config.gz ]; then
            zcat /config/config.gz > /src/linux/.config
        else
            zcat /proc/config.gz > /src/linux/.config
        fi
    fi

    cd /src/linux && make -j8
}

# Build ZFS
function build_zfs() {
    cd /src/zfs
    sh ./autogen.sh
    ./configure \
        --prefix=/ \
        --libdir=/lib \
        --with-linux=$KERNEL_SRC \
        --with-linux-obj=$KERNEL_OBJ \
        --with-config=${ZFS_CONFIG:-all}
    make -j8
    make install DESTDIR=/build
}

get_zfs_source
if [ "$ZFS_CONFIG" != "user" ]; then
    get_kernel
fi
build_zfs
