The custom-rpms documentation file gives a general overview of how to build a custom libvirt RPM for use in Kubevirt, but does not explain underlying processes.
This means that edge cases are often hard to diagnose, this document serves as a troubleshooting guide to explain why failures may occur.
Much of this information is also fully or partially included in **build-the-builder.md** and **updating-dependencies.md**, but with different goals in mind.

## Bulding libvirt in a docker container
The documentation suggest building in a docker container that is no longer being hosted (registry.gitlab.com/libvirt/libvirt/ci-centos-stream-8).
At time of writing, you should instead use `registry.gitlab.com/libvirt/libvirt/ci-centos-stream-9`.
Which matches the version of packages expected by kubevirt (see [BASESYSTEM](#BASESYSTEM-anchor)).

The next concern is getting your libvirt source into the container while not confounding file ownership.
I opted to mirror the approach used by `hack/dockerized` and rsync source into the container before build and rsync the "build" folder out after.
There are other ways to solve, but keep in mind that by default libvirt will run git commands during build.
These commands will fail with error "dubious file permissions" if the source code is owned by the user while the "build" folder is owned by root, which is the default if simply using volume mounts.
You may opt to disable the git command part of the libvirt build and simply run those commands ahead of time, or choose another option to deal with docker user ownership in/out of the container.

The `dockerized` script included in this repo runs the necessary build steps.
Scripts to build and a Dockerfile to produce the build image are included in the repo, and commented for explanation

I additionally rsync copied the `build-libvirt.bash` script into the container out of tree to run the build steps.
Libvirt only allows clean builds by default (no uncommited git changes).
This can probably be disabled, or you may simply checkin changes before each build

## The `make rpm-deps` command
TLDR: we need to set the LIBVIRT_VERSION variable to match that of the version we are building from source, and the SINGLE_ARCH variable to match what architecture we are building libvirt for (likely host arch). We *do not* need to set the BASESYSTEM variable, but the default value (centos-stream-release) implies what image version we should use for our dockerized build of libvirt

This command updates the **WORKSPACE** file and **rpms/BUILD.bazel** file according to pre-defined rules, and the currently used rpm repositories.
Inspection of the script shows that it uses several environment variables that can specify custom RPM versions to be used by the kubevirt build system.
The LIBVIRT_VERSION and QEMU_VERSION variables are the ones that are critical to running custom RPMs for libvirt and qemu respectively.
- LIBVIRT_VERSION
- QEMU_VERSION
- SEABIOS_VERSION
- EDK2_VERSION
- LIBGUESTFS_VERSION
- GUESTFSTOOLS_VERSION
- PASST_VERSION
- VIRTIOFSD_VERSION
- SWTPM_VERSION

Additionally, two more environment variables are used:
- **SINGLE_ARCH**: This variable will restrict which rpm specifications will be updated in the **WORKSPACE** and **rpms/BUILD.bazel** file.
This is required to be set in our situation, as otherwise the make command will attempt to update package requirements of other architectures (arm64 and s390x) to the version that we specify in LIBVIRT_VERSION, which will not exist in our self-hosted package repository, and likely not exist in the upstream repositories.
- **BASESYSTEM** <a id="BASESYSTEM-anchor"></a>: This will become the `--basesystem` argument to the `bazeldnf rpmtree` command, which resolves rpm trees into an individualized rpm list with precise versioning (see [bazeldnf docs](https://github.com/brianmcarey/bazeldnf) for the currently used fork of bazeldnf).
The default for this value in kubevirt build scripts is "centos-stream-release," which at the time of writing corresponds to CentOS Stream 9.
This is a reasonable value as the kubevirt builder is *currently* based on CentOS Stream 9 (see **hack/builder/Dockerfile** for the base version being used).
The **custom-rpms.md** docs mention that it is sometimes necessary to change this value, but changing the value is not necessary if using the standard kubevirt builder, and what values are valid to set for this is outside the scope of this document.

### Getting the correct LIBVIRT_VERSION
The build script automatically gets the libvirt version using the `meson introspect` within the build container and outputing the version value to **libvirt/build/version.txt**.

#### Manual version setting
The libvirt version of the compiled code can be found manually in **libvirt/meson.build** as shown:
```
project(
  'libvirt', 'c',
  version: '12.1.0',    # libvirt-version-number
  license: 'LGPLv2+',
  meson_version: '>= 0.57.0',
  default_options: [
    'buildtype=debugoptimized',
    'b_pie=true',
    'c_std=gnu99',
    'warning_level=2',
  ],
)
```
The format of the LIBVIRT_VERSION environment variable is "0:<libvirt-version-number>-1.el<centos-stream-version>", for example:
- Given the libvirt version shown (12.1.0) and using centos-stream-9 to build the rpms, you would have LIBVIRT_VERSION=0:12.1.0-1.el9
- This ***does not*** exactly match the format of the built rpm file names (i.e. libvirt-devel-12.1.0-1.el9.x86_64.rpm)

You may override the automatically populated value of LIBVIRT_VERSION by exporting the environment variable in the correct format

With the correct environment variables set, we can successfully run the `make rpm-deps` command. Running a `git diff` in the kubevirt source folder will show the updated packages being referenced. You may also see some non-libvirt packages that changed that are simply newer versions available on the remote. All libvirt dependencies should show a *url* field that references the rpm http server that is being run in docker.

