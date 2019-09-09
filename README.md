# Docker ZFS Builder

This image is designed to build ZFS on Linux for any kernel, even those that
are different from the one running on the host system. To build the latest ZFS
for the currently running system, run:

    $ docker run -v /:/build delphix/zfs-builder:latest

If you are running CentOS, and are not providing a `centos-release` config file,
you will need to launch the container in privileged mode in order to access the
host filesystem, add `--privileged --pid=host`.

If you are performing a LinuxKit or CentOS build, you will need to provide
access to launch docker containers, add `-v /var/run/docker.sock:/var/run/docker.sock`.

To configure the container to buld for a kernel other than the running system,
the following configuration options are available:

 * `-e ZFS_VERSION=zfs-0.8.0` - Version of ZFS to build. Must correspond to a tag or a
   commit hash in the `zfsonlinux/zfs` github repository. Defaults to the
   latest tag.
 * `-e KERNEL_RELEASE=4.9.125-linuxkit` - Version of the kernel interfaces to use,
   from `uname -r`.
 * `-e KERNEL_UNAME=...` - Complete `uname -a` output identifying the kernel.
 * `-v path:/build` - Output where ZFS binaries (kernel modules and userland
   tools) will be placed, using their absolute path (e.g. `/build/sbin/zfs`)
 * `-v path:/config` - Additional OS-specific content required to build.

## Supported OSes

For building userland ZFS, any OS is supported. For kernel ZFS, the build system
supports the following operating systems:

  * Ubuntu - Does not require any additional configuration. Tested with bionic,
             may or may not work for other releases.
  * LinuxKit - Requires access to the docker socket. Tested with 4.9.125 and
             later, may or may not work with other releases.
  * CentOS - Requires access to the docker socket, and either (a) privileged
             host access or (b) `/config/centos-release` from
             `/etc/centos-release`. Tested with CentOS 7, may or may not work
             with other releases.
  * Vanilla - Requires either (a) `/proc/config.gz` to be present, or
              `/config/config.gz` to be present with the kernel configuration.
              Optionally can specify the kernel source with `-v path:/src/linux`,
              otherwise source will be downloaded from `kernel.org`.

If the system isn't recognized, it will try to download and build the vanilla
kernel source that matches the given version, but (a) this will take a long
time and (b) we may or may not have the right patches and modifications in place
to build the correct version. YMMV, and no guarantees are made that the
resulting kernel binaries will work.

If you'd like to add support for a new OS, you can look at the different models
employed by Ubuntu (native download and build within container), LinuxKit
(download source via container, build locally), and CentOS (download and build
entirely within container) for different models.

## Additional configuration

While not the primary configuration parameters, the following options can also
be used:

 * `-v path:/src/zfs` - Specify the ZFS source to use. If this is present, then
   the builder will skip cloning and checking out the ZFS source, and use what's
   here instead. `ZFS_VERSION` is ignored in this case.
 * `-e ZFS_CONFIG=all|user|kernel` - Control what ZFS binaries to build,
   defaults to `all`. If `user` is specified, then the kernel build steps are
   skipped.

This builder only works with ZFS version 0.8.0 or later, as the spl repository
has been merged and no longer needs to be built separately.

## Contributing

The ZFS builder project follows the Titan community best practices:

  * [Contributing](https://github.com/titan-data/.github/blob/master/CONTRIBUTING.md)
  * [Code of Conduct](https://github.com/titan-data/.github/blob/master/CODE_OF_CONDUCT.md)
  * [Community Support](https://github.com/titan-data/.github/blob/master/SUPPORT.md)

It is maintained by the [Titan community maintainers](https://github.com/titan-data/.github/blob/master/MAINTAINERS.md)

For more information on how it works, and how to build and release new versions,
see the [Development Guidelines](DEVELOPING.md).

## License

This is code is licensed under the Apache License 2.0. Full license is
available [here](./LICENSE).
