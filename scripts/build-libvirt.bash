#!/bin/bash
# Compile and create the rpms
set -e
cd src
git status &> /dev/null     # For some reason the git repo is marked as dirty when it isn't, running status fixes it!?
meson setup build -Dsystem=true -Ddriver_qemu=enabled       # Options recommended by libvirt build docs
ninja -C build dist                                         
rpmbuild -ta    /build/src/build/meson-dist/libvirt-*.tar.xz 
# Create repomd.xml
createrepo_c -v --general-compress-type gz /root/rpmbuild/RPMS/x86_64   # Force the compress type. bazeldnf doesn't support zstd at time of writing
# Write the libvirt build version to file
meson introspect build --projectinfo | jq -r ".version" > /build/src/build/version.txt

mkdir /build/src/build/tarss
cp /build/src/build/meson-dist/libvirt-*.tar.xz /build/src/build/tarss