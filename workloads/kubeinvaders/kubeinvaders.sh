#!/bin/sh

TARGET_NAMESPACE=kubeinvaders
DOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' | sed 's/console-openshift-console.//')
ROUTE_HOST=kubeinvaders.$DOMAIN

oc new-project $TARGET_NAMESPACE --display-name='KubeInvaders' --skip-config-write=true
oc create sa kubeinvaders -n ${TARGET_NAMESPACE}
oc adm policy add-role-to-user edit -z kubeinvaders -n $TARGET_NAMESPACE

TOKEN=$(oc describe secret -n $TARGET_NAMESPACE $(oc describe sa kubeinvaders -n $TARGET_NAMESPACE | grep Tokens | awk '{ print $2}') | grep 'token:'| awk '{ print $2}')

oc process -f https://raw.githubusercontent.com/lucky-sideburn/KubeInvaders/master/openshift/KubeInvaders.yaml \
  -p ROUTE_HOST=$ROUTE_HOST \
  -p TARGET_NAMESPACE=$TARGET_NAMESPACE \
  -p TOKEN=$TOKEN | oc create -f -
