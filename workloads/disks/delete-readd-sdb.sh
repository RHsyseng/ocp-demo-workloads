#!/bin/bash

  ## Configuration Options
targetDrive="sdb"
mountedFilesystem="/mnt"

  ## Calculated Values
sysfsPath="/sys/block/${targetDrive}"
scsiController=$(readlink ${sysfsPath} | egrep -wo 'host[0-9]+')

  ## Trigger sysfs deletion
echo 1 > ${sysfsPath}/device/delete

  ## Do a lazy unmount to remove dead drive so that rescanning causes the drive name to be reclaimed
umount -l ${mountedFilesystem}

  ## Rescan the particular SCSI Host Controller that manages the target drive
echo - - - > /sys/class/scsi_host/${scsiController}/scan

  ## Manually re-mount the target drive on the specified filesystem path
mount /dev/${targetDrive} ${mountedFilesystem}
