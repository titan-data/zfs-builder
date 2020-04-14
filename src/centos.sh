#!/bin/bash
#
# Copyright The Titan Project Contributors.
#

#
# Get centos-specific modules. Rather than trying to install the modules directly within
# our Ubuntu container, we instead launch a centos docker container, which will allow us
# to 'yum install' the relevant packages natively. Unfortunately, CentOS does
# not make it easy to map from uname output to centos version as used to label
# docker images. Rather than having to maintain an internal list here that
# needs to be updated, we instead require that users mount /etc onto /config so
# that we can access /etc/centos-release, which does have the right string.
#
# If this wasn't enough, CentOS requires a customized version of GCC that is not available
# in the stock Ubuntu gcc images. So we can't run the actual build from within
# our container, but instead run the whole build process via centos-build.
# within the container.
#
# Finally, CentOS is aggressive about moving older kernel versions to their "vault"
# repos. Because of this, we allow the "centos-vault" file in the config to specify
# content that should replace /etc/yum.repos.d/CentOS-Vault.repo, such as:
#
#     [C7.6.1810]
#     name=CentOS-7.6.1810
#     baseurl=http://vault.centos.org/7.6.1810/updates/$basearch/
#     gpgcheck=1
#     gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
#     enabled=1
#
# This allows tools that invoke the builder to indicate where exactly to find
# the centos packages.
#
function build() {
    local centos_release
    if [[ -f /config/centos-release ]]; then
        centos_release=$(cat /config/centos-release)
    else
        centos_release=$(nsenter -t 1 -m cat /etc/centos-release)
    fi
    local regex="CentOS Linux release ([0-9\.]+)"
    if [[ $centos_release =~ $regex ]]; then
        local centos_version="${BASH_REMATCH[1]}"
    else
        echo "failed to determine CentOS release from centos-release"
        exit 1
    fi

    mkdir /docker
    cp /*.sh /docker
    if [[ -f /config/centos-vault ]]; then
      cp /config/centos-vault /docker
    else
      touch /docker/centos-vault
    fi
    cat > /docker/Dockerfile <<EOF
FROM centos:centos$centos_version
RUN yum install -y dnf-plugins-core
RUN yum config-manager --set-enabled PowerTools
RUN yum install -y gcc git
RUN yum install -y autoconf automake libtool make rpm-build ksh
RUN yum install -y zlib-devel libuuid-devel libattr-devel libblkid-devel libselinux-devel libudev-devel
RUN yum install -y libacl-devel libaio-devel device-mapper-devel openssl-devel libtirpc-devel elfutils-libelf-devel
RUN yum install -y epel-release
COPY *.sh /
COPY centos-vault /etc/yum.repos.d/CentOS-Vault.repo
CMD /centos-build.sh
EOF
    local image_name=zfs-builder-centos:$(generate_random_string 8)
    cd /docker && docker build -t $image_name .

    local container_name=zfs-builder-$(generate_random_string 8)
    docker run --name $container_name -e KERNEL_RELEASE=$KERNEL_RELEASE $image_name
    docker cp $container_name:/build /

    docker rm $container_name
    docker rmi $image_name
}
