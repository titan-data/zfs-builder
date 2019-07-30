#
# Copyright (c) 2019 by Delphix. All rights reserved.
#

FROM ubuntu:bionic

ARG KERNEL_RELEASE=
ARG KERNEL_UNAME=
ARG ZFS_VERSION=

RUN apt-get update

RUN apt-get install -y                                                       \
    git	                                                                     \
    curl xz-utils                                                            \
    build-essential bc                                                       \
    autoconf automake libtool kmod                                           \
    zlib1g-dev uuid-dev libattr1-dev libblkid-dev libselinux-dev libudev-dev \
    libacl1-dev libaio-dev libdevmapper-dev libssl-dev libelf-dev

RUN mkdir /src
RUN mkdir /build

COPY build.sh /

CMD /build.sh
