# Docker ZFS Builder

This image is designed to build ZFS on Linux for any kernel, even those that
are different from the one running on the host system. To build the latest ZFS
for the currently running system, run:

    $ docker run -v /:/build delphix/zfs-builder:latest

To configure the container to buld for a kernel other than the running system,
the following configuration options are available:

 * `-e ZFS_VERSION=zfs-0.8.0` - Version of ZFS to build. Must correspond to a tag or a
   commit hash in the `zfsonlinux/zfs` github repository. Defaults to the
   latest tag.
 * `-e KERNEL_RELEASE=4.9.125-linuxkit` - Version of the kernel interfaces to use,
   from `uname -r`. If the variant (e.g. "linuxkit") is known, then we will pull
   kernel headers via the distro-specific mechanisms. Otherwise, we will try to
   use the version published on `kernel.org`, though it's possible that the system
   is running with unknown patches to those sources. Defaults to `uname -r`. If
   you are building for a distro for the first time, you might want to submit
   a pull request to grab the appropriate kernel source.
 * `-v path:/config` - Kernel configuration to use for building the kernel.
   Must contain a single file, `config.gz`. Defaults to `/proc/config.gz`.
 * `-v path:/build` - Output where ZFS binaries (kernel modules and userland
   tools) will be placed, using their absolute path (e.g. `/build/sbin/zfs`)

## Additional configuration

While not the primary configuration parameters, the following options can also
be used:

 * `-v path:/src/zfs` - Specify the ZFS source to use. If this is present, then
   the builder will skip cloning and checking out the ZFS source, and use what's
   here instead. `ZFS_VERSION` is ignored in this case.
 * `-v path:/src/linux` - Like above, if this is present then the builder will
   skip downloading the kernel source. It will still copy `config.gz` unless
   `.config` is already present in this directory. `KERNEL_RELEASE` is ignored
   in this case. 
 * `-e ZFS_CONFIG=<all|user|kernel>` - Control what ZFS binaries to build,
   defaults to `all`. If `user` is specified, then the kernel build steps are
   skipped.

This builder only works with ZFS version 0.8.0 or later, as the spl repository
has been merged and no longer needs to be built separately.

## How it works

ZFS, like other kernel modules, has a dependency on the interfaces of the
running kernel. Normally, this is built against the currently running kernel.
But this creates challenges for users to always install all the requisite build
tools and find the requisite kernel source, not to mention cases where you
might want to build packages for a kernel other than the one you are currently
running (such as part of an automated process using standard build machines).

To accomplish this, the ZFS builder does the following:

 1. Clone `https://github.com/zfsonlinux/zfs.git` into `/src/zfs` and
    checks out the appropriate tag (unless `/src/zfs` already exists)
 2. Build the kernel, if necessary. First check the kernel release variant and,
    if a known distro, download kernel source through the distro-specific
    means. Otherwise get the source from `www.kernel.org`.  Copy the `config.gz`
    configuration to `/src/kernel/.config`. Build the kernel.
 3. Build `/src/zfs`
 4. Copy the resulting binaries to `/build`

## <a id="contribute"></a>Contribute

1.  Fork the project.
2.  Make your bug fix or new feature.
3.  Add tests for your code.
4.  Send a pull request.

Contributions must be signed as `User Name <user@email.com>`. Make sure to
[set up Git with user name and email address](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup).
All development should be done on the `master` branch.

#### <a id="code-of-conduct"></a>Code of Conduct

This project operates under the
[Delphix Code of Conduct](https://delphix.github.io/code-of-conduct.html). By
participating in this project you agree to abide by its terms.

#### <a id="contributor-agreement"></a>Contributor Agreement

All contributors are required to sign the Delphix Contributor agreement prior
to contributing code to an open source repository. This process is handled
automatically by [cla-assistant](https://cla-assistant.io/). Simply open a pull
request and a bot will automatically check to see if you have signed the latest
agreement. If not, you will be prompted to do so as part of the pull request
process.


## <a id="reporting_issues"></a>Reporting Issues

Issues should be reported [here](https://github.com/delphix/automation-framework-demo/issues).

## <a id="statement-of-support"></a>Statement of Support

This software is provided as-is, without warranty of any kind or commercial
support through Delphix. See the associated license for additional details.
Questions, issues, feature requests, and contributions should be directed to
the community as outlined in the
[Delphix Community Guidelines](https://delphix.github.io/community-guidelines.html).

## <a id="license"></a>License

This is code is licensed under the Apache License 2.0. Full license is
available [here](./LICENSE).
