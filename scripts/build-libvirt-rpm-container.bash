#!/bin/bash

if [[ -z "$LIBVIRT_DIR" ]]; then
  echo "The variable 'LIBVIRT_DIR' is not defined."
  exit 1
fi

docker volume create rpms
docker run -td -w /libvirt-src --security-opt label=disable --name libvirt-build -v ${LIBVIRT_DIR}:/libvirt-src --workdir /libvirt-src -v rpms:/root/rpmbuild/RPMS registry.gitlab.com/libvirt/libvirt/ci-centos-stream-10
docker exec -i libvirt-build /bin/bash < build-libvirt.bash
docker rm -f libvirt-build