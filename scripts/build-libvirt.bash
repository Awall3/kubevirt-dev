#!/bin/bash
# Make sure we get all the latest packages
# Compile and create the rpms
set -e
pwd
meson setup build -Dsystem=true -Ddriver_qemu=enabled
ninja -C build dist
rpmbuild -ta    /libvirt-src/build/meson-dist/libvirt-*.tar.xz 
# Create repomd.xml
createrepo -v  /root/rpmbuild/RPMS/x86_64