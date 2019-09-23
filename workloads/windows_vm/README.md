# Steps

```
bash deploy_windows.sh
oc new-project demo
oc create -f nad_brext.yml -n demo
oc create -f pvc_windows.yml -n demo
oc create -f vm_windows.yml -n demo
```
