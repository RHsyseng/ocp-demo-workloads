#!/bin/bash

OPERATORS_NAMESPACE="openshift-operators"
TKN_VERSION="0.2.2"

set -ex

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

oc create -f http://bit.ly/pipelines-demo || true

# First time it fails because some components are not deployed
# oc create -f http://bit.ly/pipelines-demo
# namespace/pipelines-demo created
# role.rbac.authorization.k8s.io/pipeline created
# rolebinding.rbac.authorization.k8s.io/default-pipeline-binding created
# rolebinding.authorization.openshift.io/default-admin-binding created
# imagestream.image.openshift.io/spring-petclinic created
# deploymentconfig.apps.openshift.io/spring-petclinic created
# service/spring-petclinic created
# route.route.openshift.io/spring-petclinic created
# pipeline.tekton.dev/petclinic-pipeline created
# unable to recognize "http://bit.ly/pipelines-demo": no matches for kind "Task" # in version "tekton.dev/v1alpha1"
# unable to recognize "http://bit.ly/pipelines-demo": no matches for kind "Task" # in version "tekton.dev/v1alpha1"
# unable to recognize "http://bit.ly/pipelines-demo": no matches for kind  "PipelineResource" in version "tekton.dev/v1alpha1"
# unable to recognize "http://bit.ly/pipelines-demo": no matches for kind  "PipelineResource" in version "tekton.dev/v1alpha1"
# So... sleep a bit and try again

sleep 30
oc create -f http://bit.ly/pipelines-demo || true

oc project pipelines-demo

tkn pipeline start petclinic-pipeline -r app-git=petclinic-git -r app-image=petclinic-image
