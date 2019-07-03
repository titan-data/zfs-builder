#!/bin/bash
#
# Copyright (c) 2019 by Delphix. All rights reserved.
#

set -xe

# Checkout ZFS source
function get_zfs_source() {
    if [ ! -d /src/zfs ]; then
        git clone https://github.com/zfsonlinux/zfs.git /src/zfs
        cd /src/zfs
        [ -z $ZFS_VERSION ] && ZFS_VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)
        git checkout $ZFS_VERSION
    fi
}

# Get linuxkit-specific headers
function get_linuxkit_src() {
    local version=$1
    curl --retry 5 -o /src/linuxkit-$version.tar.gz -L https://github.com/linuxkit/linux/archive/v${version}.tar.gz
    cd /src
    tar xf linuxkit-$version.tar.gz
    mv linux-$version linux
    rm linuxkit-$version.tar.gz
}

# Get vanilla headers
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
function get_kernel_source() {
    [ -z $KERNEL_RELEASE ] && KERNEL_RELEASE=$(uname -r)
    local kernel_version=${KERNEL_RELEASE%%-*}
    local kernel_variant=${KERNEL_RELEASE#*-}

    case $kernel_variant in
    linuxkit)
        get_linuxkit_src $kernel_version $kernel_variant
        ;;
    *)
        get_vanilla_src $kernel_version $kernel_variant
        ;;
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
        --with-linux=/src/linux \
        --with-linux-obj=/src/linux \
        --with-config=${ZFS_CONFIG:-all}
    make -j8
    make install DESTDIR=/build
}

get_zfs_source
if [ "$ZFS_CONFIG" != "user" ]; then
    get_kernel_source
    build_kernel
fi
build_zfs
