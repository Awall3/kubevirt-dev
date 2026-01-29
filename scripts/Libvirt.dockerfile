FROM registry.gitlab.com/libvirt/libvirt/ci-centos-stream-10

RUN dnf update -y && dnf builddep libvirt

RUN mkdir -p /home/user/.ccache
RUN chmod 0777 -R /home
ENV CCACHE_DIR=/home/user/.ccache
ENV HOME=/home/user
