#!/bin/bash
set +x

LIBVIRT_VERSION=${LIBVIRT_VERSION:-"0:12.1.0-1.el9"}

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [[ -z "$LIBVIRT_DIR" ]]; then
  echo "The variable 'LIBVIRT_DIR' is not defined."
  exit 1
fi

if [[ -z "$KUBEVIRT_DIR" ]]; then
  echo "The variable 'KUBEVIRT_DIR' is not defined."
  exit 1
fi

(
  set -e

  # Pulled from custom-rpms.md (creates a shared docker volume for built RPMs)
  docker volume create rpms
  # Build the CentOS Stream 9 image with some extra dependencies
  docker build -t libvirt-build-image -f Libvirt.dockerfile . 

  # Override build image for dockerized to our local build
  export LIBVIRT_BUILDER_IMAGE=libvirt-build-image

  # Mount the rpm volume to the default build output directory for libvirt RPMs
  export EXTRA_VOLS="-v rpms:/root/rpmbuild/RPMS"

  # Host-side path to build script
  export LIBVIRT_BUILD_SCRIPT="${SCRIPT_DIR}/build-libvirt.bash"

  # Pass the container-side path to the script (it will be rsynced to the cwd in the container)
  ./dockerized ./build-libvirt.bash

  # Mount the same rpm volume to an httpd container, and output it's IP to the "${KUBEVIRT_DIR}/manifests/generated/custom-repo.tmp" file
  # This file MUST be in the kubevirt source directory in a non-ignored location (see rsync commands in ${KUBEVIRT_DIR}/hack/dockerized), 
  # otherwise it will not be copied into the build container. The manifests/generated folder is an arbitrary selection that is gitignored but not rsync ignored
  docker run -dit --name rpms-http-server -p 80 -v rpms:/usr/local/apache2/htdocs/ httpd:latest
  DOCKER_URL=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rpms-http-server)
  sed "s|DOCKER_URL|$DOCKER_URL|g" ${SCRIPT_DIR}/custom-repo.yaml > ${KUBEVIRT_DIR}/manifests/generated/custom-repo.tmp


  # Run the `make rpm-deps` command, adding our rpm host as a repo and setting other args as described in the building-libvirt doc 
  pushd ${KUBEVIRT_DIR}
  make CUSTOM_REPO=manifests/generated/custom-repo.tmp LIBVIRT_VERSION=${LIBVIRT_VERSION} SINGLE_ARCH="x86_64" rpm-deps
  popd
)