# YAML Definitions for RHEL8 VM workload

- [`rhel8_pvc.yaml`](./rhel8_pvc.yaml) PersistentVolumeClaim with CDI notation that pulls in the vanilla .qcow2 image from the customer portal.

NOTE: Replace the `cdi.kubevirt.io/storage.import.endpoint: "http://1.1.1.1/rhel8.qcow2"` label with the proper location of the qcow2 file.

- [`rhel8_ssh_service.yaml`](./rhel8_ssh_service.yaml) Defines a NodePort service that locates the vmi with the label of `rhel8` (please note that this is slightly different than what's needed for a VM from template)
- [`rhel8_vm.yaml`](./rhel8_vm.yaml) static definition for a single VirtualMachine object instance. There are labels of `app=rhel8` on both the `vm` and the `vmi` objects.
- [`rhel8_vm_template.yaml`](./rhel8_vm_template.yaml) OpenShift template for creating new VirtualMachine objects. Parameters are `PVCNAME` (which is always `rhel8-pvc` here) and `NAME`.
