#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

#
# Build process for the WSL2 (Windows Service for Linux 2) kernel. The kernel is
# available at:
#
# https://github.com/microsoft/WSL2-Linux-Kernel
#
# However, there do not appear to be any pre-built binary packages, so we need
# to fetch the kernel source and build it ourselves. Like the vanilla kernel
# build process, we need a config.gz file to make sure we're building with the
# appropriate kernel parameters.
#

# Get vanilla kernel source
function get_kernel_src() {
    local version=$KERNEL_VERSION

    # Download Kernel source
    if [ ! -d /src/linux ]; then
        curl --retry 5 -o /src/$KERNEL_RELEASE.tar.gz -L https://github.com/microsoft/WSL2-Linux-Kernel/archive/$KERNEL_RELEASE.tar.gz
        cd /src
        bsdtar xf $KERNEL_RELEASE.tar.gz
        mv WSL2-Linux-Kernel-$KERNEL_RELEASE linux
        rm $KERNEL_RELEASE.tar.gz
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
