#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

#
# Get linuxkit-specific source. With linuxkit, the canonical data source is through
# docker images, so we launch a docker container and then copy out the data we need.
# The linuxkit images have no usable binaries, so we launch with a command that we
# know will fail, and then simply ignore the failure. The container will persist
# in the stopped state so we can copy the necessary data out of it.
#
function get_kernel() {
    local container_name=zfs-builder-$(generate_random_string 8)
    docker run --name $container_name linuxkit/kernel:$KERNEL_VERSION /ignore || /bin/true
    cd /
    docker cp $container_name:kernel-dev.tar .
    docker cp $container_name:kernel.tar .
    bsdtar xf kernel-dev.tar
    bsdtar xf kernel.tar

    cd /src
    docker cp $container_name:linux.tar.xz .
    bsdtar xf linux.tar.xz

    docker rm $container_name

    KERNEL_SRC=/src/linux
    KERNEL_OBJ=/lib/modules/$KERNEL_RELEASE/build
}

function build() {
    get_zfs_source
    if [ "$ZFS_CONFIG" != "user" ]; then
        get_kernel
    fi
    build_zfs
}
