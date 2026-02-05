source $HOME/.bashrc
_kubectl() {
    ${KUBEVIRT_DIR}/kubevirtci/cluster-up/kubectl.sh $@
}
_virtctl() {
    # virtctl fails to execute with different cwd (I think?)
    pushd ${KUBEVIRT_DIR}
    ./hack/virtctl.sh $@
    popd
}

_cli() {
    ${KUBEVIRT_DIR}/kubevirtci/cluster-up/cli.sh $@
}

_ssh() {
    ${KUBEVIRT_DIR}/kubevirtci/cluster-up/ssh.sh $@
}

clusterup() {
    pushd /home/awallace/repos/kubevirt/
    make cluster-up
    popd
}

clustersync() {
    pushd /home/awallace/repos/kubevirt/
    make cluster-sync
    popd
}
clusterdown() {
    pushd /home/awallace/repos/kubevirt/
    make cluster-down
    popd
}