#!/usr/bin/bash

NAMESPACE="demo"
oc new-project $NAMESPACE
oc create -f nad_brext.yml -n $NAMESPACE
oc create -f pvc_windows.yml -n $NAMESPACE
oc create -f vm_windows.yml -n $NAMESPACE
