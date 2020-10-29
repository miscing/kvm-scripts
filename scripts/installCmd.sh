#!/bin/bash
#
# Copyright 2020 Alexander Saastamoinen
#
#  Licensed under the EUPL, Version 1.2 or – as soon they
# will be approved by the European Commission - subsequent
# versions of the EUPL (the "Licence");
#  You may not use this work except in compliance with the
# Licence.
#  You may obtain a copy of the Licence at:
#
#  https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
#  Unless required by applicable law or agreed to in
# writing, software distributed under the Licence is
# distributed on an "AS IS" basis,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#  See the Licence for the specific language governing
# permissions and limitations under the Licence.
#


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

