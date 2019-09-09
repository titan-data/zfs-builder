# ZFS Builder Development

For general information about contributing changes, see the
[Contributor Guidelines](https://github.com/titan-data/.github/blob/master/CONTRIBUTING.md).

## How it Works

ZFS, like other kernel modules, has a dependency on the interfaces of the
running kernel. Normally, this is built against the currently running kernel.
But this creates challenges for users to always install all the requisite build
tools and find the requisite kernel source, not to mention cases where you
might want to build packages for a kernel other than the one you are currently
running (such as part of an automated process using standard build machines).

The ZFS builder will determine the build strategy based on the kernel variant
being used. This strategy could build within the running container, could
fetch pre-existing binaries, or simple build from source. The ZFS builder
container is always launched with privileges to run other docker containers,
so that systems that need it (CentOS and LinuxKit, for example) can build
images and/or run containers.

Each build strategy consists of some combination of:

 1. Clone `https://github.com/zfsonlinux/zfs.git`
 2. If a kernel build is required, download or build kernel-specific modules and
    headers
 3. Build ZFS
 4. Copy the resulting binaries to `/build`

### Adding new support

All of the docker files are located under `src/`. The `build.sh` file kicks off
the main build process, which consists of:

  * Determine the build variant to use, based on uname values (e.g. `ubuntu`)
  * Invoke the `build()` function in the variant-specific build file (e.g. `ubuntu.sh`)

This provides maximum flexibility for a new variant to implement whatever build
process they need. This could include downloading special packages, running
containers, etc. For example, Ubuntu will run the build within the current image,
while CentOS will launch a separate CentOS container to actually do the build.

There are a number of helper functions in `common.sh` that are used across
platforms, mostly to fetch and build ZFS source. These can be invoked at the
appropriate point within the variant-specific build process. For example,
LinuxKit and Ubuntu invoke them within the build container, while CentOS
propagates it into a custom container to do the whole build.

## Building

The build process is very simple, just run `docker build -t <tag> .`.

## Testing

There are no built-in tests. You can test a variety of platforms using
the [zfs-builds](https://github.com/titan-data/zfs-builds) repository. You can
test a single affected platform or, if you are making broad changes, across
every known platform.

## Releasing

 This repository is connected to the [titandata](https://hub.docker.com/u/titandata)
 DockerHub organization via GitHub actions. It uses the standard DockerHub
 build infrastructure to automatically build new images:

  * Every push will update the `:develop` tag
  * Every release will update the `:latest` tag
  * Every release will create a `:[release]` tag

New release should be named `v[major].[minor].[patch]`. While there are no
strict rules, major releases should be reserved for changes that backwards
compatibility with how the container is invoked. Minor releases should be
reserved for forward-compatible changes to how it's invoked (e.g. a new
option for a particular variant). Patch releases should be reserved for all
other changes (including new variant support).
