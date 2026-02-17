#!/bin/bash
echo "start"
source common.sh
_kubectl apply -f ../sandbox/vmi-alpine-efi.yaml
_kubectl wait --for=jsonpath='{.status.phase}'=Running pod -l special=vmi-alpine-efi
_kubectl port-forward $(_kubectl get pods | grep virt-launcher | awk '{print $1}') 2345
echo "done forwarding"
