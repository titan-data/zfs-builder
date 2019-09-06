#!/bin/bash
#
# Copyright (c) 2019 by Delphix. All rights reserved.
#

set -xe

. $(dirname $0)/common.sh

#
# This script is invoked within the context of the centos container, so  we can
# execute native yum commands.
#
CENTOS_KERNEL=${KERNEL_RELEASE%%.x86_64}

yum install -y kernel-devel-$CENTOS_KERNEL kernel-$CENTOS_KERNEL

KERNEL_SRC=/usr/src/kernels/$KERNEL_RELEASE
KERNEL_OBJ=/lib/modules/$KERNEL_RELEASE/build

get_zfs_source
build_zfs
