#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

set -xe

. $(dirname $0)/common.sh

function get_kernel_vars() {
    [ -z "$KERNEL_RELEASE" ] && KERNEL_RELEASE=$(uname -r)
    [ -z "$KERNEL_UNAME" ] && KERNEL_UNAME=$(uname -a)
    KERNEL_VERSION=${KERNEL_RELEASE%%-*}
    KERNEL_VARIANT=${KERNEL_RELEASE#*-}
}

function get_kernel_type() {
    case $KERNEL_VARIANT in
    linuxkit)
        echo linuxkit
        ;;
    microsoft-standard)
        echo wsl
        ;;
    *)
        case $KERNEL_UNAME in
        *Ubuntu*)
            echo ubuntu
            ;;
        *.el[0-9].*)
            echo centos
            ;;
        *.el8_[0-9].*)
	    echo centos8x
            ;;
        *)
            echo vanilla
            ;;
        esac
    esac
}

if [ "$ZFS_CONFIG" != "user" ]; then
    get_kernel_vars
    kernel_type=$(get_kernel_type)
else
    kernel_type=vanilla
fi

. $(dirname $0)/$kernel_type.sh
build
