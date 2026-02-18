#!/bin/bash
set -e

rpmdev-setuptree
rm -rf qemu-99.99.99
mv qemu qemu-99.99.99
tar --exclude build -cf /build/qemu-99.99.99.tar.xz qemu-99.99.99
cp /build/qemu-*.tar.xz /root/rpmbuild/SOURCES
cp /build/qemu-kvm/* /root/rpmbuild/SOURCES
cp /build/qemu-kvm/qemu-kvm.spec /root/rpmbuild/SPECS

# rpmbuild -ta /build/qemu-*.tar.xz 
cd /root/rpmbuild/SPECS
rpmbuild -ba qemu-kvm.spec --nocheck --define '_smp_mflags -j12'
createrepo_c -v --general-compress-type gz /root/rpmbuild/RPMS/x86_64   # Force the compress type. bazeldnf doesn't support zstd at time of writing
