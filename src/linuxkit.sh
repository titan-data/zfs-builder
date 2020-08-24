#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

#
# Get linuxkit-specific source. With linuxkit, the canonical data source is through
# docker images, so we launch a docker container and then copy out the data we need.
# The linuxkit images have no usable binaries, so we launch an alpine container from
# the linuxkit kernel image with the required zfs build dependencies.
#

function build() {
    local linuxkit_release

    mkdir /docker
    cp /*.sh /docker

    cat > /docker/Dockerfile <<EOF
FROM linuxkit/kernel:$KERNEL_VERSION AS ksrc
FROM linuxkit/alpine:5fd4e83fea8bd04f21d1611d04c93d6ccaca785a AS build
RUN apk update
RUN apk add bash \
    attr-dev \
    autoconf \
    automake \
    build-base \
    gettext-dev \
    git \
    gettext-dev \
    linux-headers \
    libtirpc-dev \
    libintl \
    libtool \
    libressl-dev \
    util-linux-dev \
    zlib-dev \
    zfs-libs
COPY --from=ksrc /kernel-dev.tar /
RUN tar xf kernel-dev.tar
COPY *.sh /
CMD /linuxkit-build.sh
EOF
    local image_name=zfs-builder-linuxkit:$(generate_random_string 8)
    cd /docker && docker build -t $image_name .
    local container_name=zfs-builder-$(generate_random_string 8)
    docker run --name $container_name -e KERNEL_RELEASE=$KERNEL_RELEASE -e ZFS_VERSION=$ZFS_VERSION \
        -e KERNEL_SRC=/src/linux -e KERNEL_OBJ=/lib/modules/$KERNEL_RELEASE/build $image_name
    docker cp $container_name:/build /
    docker rm $container_name
    docker rmi $image_name
}
