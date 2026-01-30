#!/bin/bash
# Compile and create the rpms
set -e
cd libvirt
git status &> /dev/null # For some reason the git repo is marked as dirty when it isn't, running status fixes it!?
meson setup build -Dsystem=true -Ddriver_qemu=enabled
ninja -C build dist
rpmbuild -ta    /build/libvirt/build/meson-dist/libvirt-*.tar.xz 
# Create repomd.xml
createrepo_c -v  /root/rpmbuild/RPMS/x86_64