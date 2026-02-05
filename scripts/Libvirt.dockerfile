FROM registry.gitlab.com/libvirt/libvirt/ci-centos-stream-9

RUN dnf update -y && dnf builddep libvirt

RUN dnf install -y \
    rsync \
    createrepo_c

RUN cat <<EOF > /etc/rsyncd.conf
read only = no
uid = root
gid = root
[build] 
    path = /root
    comment = Libvirt source
EOF