#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname $0)
RIPSAW_NS="my-ripsaw"
RIPSAW_SUBSCRIPTION_NAME="my-ripsaw"

function printe {
    echo -e "\e[31m===> [ERROR] ${1}\e[0m"
}

function printc {
    echo -e "\e[1;36m===> ${1}\e[0m"
}

function check_kubeconfig {
    if [ -z ${KUBECONFIG:-} ]; then
        if [ ! -f ${HOME}/.kube/config ]; then
            printe "No kubeconfig found, exiting"
            exit 1
        fi
    fi
}

printc "Checking for kubeconfig..."
check_kubeconfig

printc "Checking if ripsaw operator is available in the community-operators"
if ! $(oc get opsrc community-operators -o=custom-columns=NAME:.metadata.name,PACKAGES:.status.packages -n openshift-marketplace | grep -q ripsaw); then
  printe "ripsaw operator not available in the community-operators"
  exit 2
fi

printc "Creating Ripsaw NS ${RIPSAW_NS}"
oc create ns ${RIPSAW_NS}

printc "Creating Ripsaw OLM subscription"

cat << EOF | oc create -f -
---
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: operatorgroup
  namespace: ${RIPSAW_NS}
spec:
  targetNamespaces:
  - ${RIPSAW_NS}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${RIPSAW_SUBSCRIPTION_NAME}
  namespace: ${RIPSAW_NS}
spec:
  channel: alpha
  name: ripsaw
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

sleep 10

while ! oc wait --for condition=ready pods -l name=benchmark-operator -n ${RIPSAW_NS} --timeout=2400s; do sleep 10 ; done

printc "Done! Ripsaw is ready to use!"
