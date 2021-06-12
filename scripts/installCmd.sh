#!/bin/bash

USAGE="$0 [cloudinit_filename_in_tmp] /dev/path vm_name"

if [[ $# == 3 ]]; then
	cloudinit=$1
	vmname=$3
	devpath=$2
elif [[ $# == 2 ]]; then
	cloudinit="cloudinit.iso"
	vmname=$3
	devpath=$2
else
	echo -e $USAGE
	exit 1
fi


if [[ -f /tmp/$cloudinit ]]; then
	echo mounting /tmp/$cloudinit as cdrom
	virt-install --name $vmname --memory 8192 --vcpus 4 --graphics none --import --disk path=$devpath --cdrom /tmp/$cloudinit
else
	virt-install --name $vmname --memory 8192 --vcpus 4 --graphics none --import --disk path=$devpath
fi

