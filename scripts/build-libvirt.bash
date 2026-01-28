#!/bin/bash
# Make sure we get all the latest packages
# dnf update -y
# Compile and create the rpms
set -e
pwd
meson setup build -Dsystem=true -Ddriver_qemu=enabled
ninja -C build dist