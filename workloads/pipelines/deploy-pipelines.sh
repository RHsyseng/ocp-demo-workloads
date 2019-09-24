#!/bin/bash
set -ex
OPERATORS_NAMESPACE="openshift-operators"
TKN_VERSION="0.3.1"
PIPELINESNAMESPACE="pipelines-tutorial"

# Create a subscription
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: ${OPERATORS_NAMESPACE}
spec:
  channel: dev-preview
  installPlanApproval: Automatic
  name: openshift-pipelines-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
  startingCSV: openshift-pipelines-operator.v0.5.2
EOF

echo "Give the pipeline operator some time to start..."

while [ "x" == "x$(oc get pods -l name=openshift-pipelines-operator -n ${OPERATORS_NAMESPACE} 2> /dev/null)" ]; do
    sleep 10
done

oc wait --for condition=ready pod -l name=openshift-pipelines-operator -n ${OPERATORS_NAMESPACE} --timeout=2400s

curl -LO https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_x86_64.tar.gz

sudo tar xvzf tkn_${TKN_VERSION}_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
rm -f tkn_${TKN_VERSION}_Linux_x86_64.tar.gz

# From https://github.com/openshift/pipelines-tutorial

oc new-project ${PIPELINESNAMESPACE} --skip-config-write=true

oc create serviceaccount pipeline -n ${PIPELINESNAMESPACE}

oc adm policy add-scc-to-user privileged -z pipeline -n ${PIPELINESNAMESPACE}
oc adm policy add-role-to-user edit -z pipeline -n ${PIPELINESNAMESPACE}

oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/resources/petclinic.yaml -n ${PIPELINESNAMESPACE}
oc create -f https://raw.githubusercontent.com/tektoncd/catalog/master/openshift-client/openshift-client-task.yaml -n ${PIPELINESNAMESPACE}
oc create -f https://raw.githubusercontent.com/openshift/pipelines-catalog/master/s2i-java-8/s2i-java-8-task.yaml -n ${PIPELINESNAMESPACE}
oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/resources/petclinic-deploy-pipeline.yaml -n ${PIPELINESNAMESPACE}
oc create -f https://raw.githubusercontent.com/openshift/pipelines-tutorial/master/resources/petclinic-resources.yaml -n ${PIPELINESNAMESPACE}

tkn pipeline start petclinic-deploy-pipeline \
        -r app-git=petclinic-git \
        -r app-image=petclinic-image \
        -s pipeline -n ${PIPELINESNAMESPACE}
