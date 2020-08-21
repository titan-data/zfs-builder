#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

set -xe

. $(dirname $0)/common.sh

get_zfs_source

cd /src/zfs
sh ./autogen.sh
./configure
make -j8
make install DESTDIR=/build