#!/bin/bash
#
# Copyright (c) 2019 by Delphix. All rights reserved.
#

#
# Get ubuntu-specific modules. With Ubuntu, we can get the pre-built modules and
# headers for a given kernel release, so that we don't need to actually build from source.
#
function get_kernel() {
    apt-get update
    apt-get install -y linux-modules-$KERNEL_RELEASE linux-headers-$KERNEL_RELEASE linux-source-$KERNEL_VERSION
    cd /usr/src && tar -xjf linux-source-$KERNEL_VERSION.tar.bz2

    KERNEL_SRC=/usr/src/linux-source-$KERNEL_VERSION
    KERNEL_OBJ=/lib/modules/$KERNEL_RELEASE/build
}

function build() {
    get_zfs_source
    if [ "$ZFS_CONFIG" != "user" ]; then
        get_kernel
    fi
    build_zfs
}
