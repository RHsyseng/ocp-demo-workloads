# Windows VM

The [`deploy-windows.sh`](./deploy-windows.sh) script will deploy a Windows VM
using a `NetworkAttachmentDefinition` to bind the network interface into a `brext` bridge in the nodes.

NOTE: Replace the `cdi.kubevirt.io/storage.import.endpoint: "cdi.kubevirt.io/storage.import.endpoint: "http://1.1.1.1/windowsvm.raw"` label with the proper location of the raw file.
