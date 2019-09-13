#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

# Get vanilla kernel source
function get_kernel_src() {
    local version=$KERNEL_VERSION

    # Download Kernel source
    if [ ! -d /src/linux ]; then
        curl --retry 5 -o /src/linux-$version.tar.xz -L https://www.kernel.org/pub/linux/kernel/v${version%%.*}.x/linux-$version.tar.xz
        cd /src
        tar xf linux-$version.tar.xz
        mv $linux-version linux
        rm linux-$version.tar.xz
    fi

    KERNEL_SRC=/src/linux
    KERNEL_OBJ=/src/linux
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

# Vanilla entry point
function build() {
    get_zfs_source
    if [ "$ZFS_CONFIG" != "user" ]; then
    	get_kernel_src
    	build_kernel
    fi
    build_zfs
}
