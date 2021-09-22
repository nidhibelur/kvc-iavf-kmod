#!/bin/bash
set -eu

export NODE_LABEL=$1; shift
export KUBECONFIG=$1; shift

IP_ADDR=$(oc get node -l node-role.kubernetes.io/${NODE_LABEL} -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | awk '{print $1;}')

KERNEL_VERSION=$(ssh -o StrictHostKeyChecking=no core@${IP_ADDR} uname -r)

echo $KERNEL_VERSION
