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

  docker volume create rpms
  docker build -t libvirt-build-image -f Libvirt.dockerfile . 

  export LIBVIRT_BUILDER_IMAGE=libvirt-build-image
  export EXTRA_VOLS="-v rpms:/root/rpmbuild/RPMS"
  export LIBVIRT_BUILD_SCRIPT="${SCRIPT_DIR}/build-libvirt.bash"
  ./dockerized ./build-libvirt.bash

  docker run -dit --name rpms-http-server -p 80 -v rpms:/usr/local/apache2/htdocs/ httpd:latest
  DOCKER_URL=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rpms-http-server)
  sed "s|DOCKER_URL|$DOCKER_URL|g" ${SCRIPT_DIR}/custom-repo.yaml > ${KUBEVIRT_DIR}/manifests/generated/custom-repo.tmp


  pushd ${KUBEVIRT_DIR}
  make CUSTOM_REPO=manifests/generated/custom-repo.tmp LIBVIRT_VERSION=${LIBVIRT_VERSION} rpm-deps
  popd
)

if [[ -z "$KEEP_RPM_SERVER" ]]; then
  docker rm -f rpms-http-server &> /dev/null
fi