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


USAGE="$0 vm_name vm_name2..."

for vm_name in "$@"; do 
	if [[ ! $vm_name =~ ^[[:alnum:]]*$ ]]; then
		echo arguments must be alphanumeric, invalid arg: $vm_name
		echo -e $USAGE
		exit 1
	fi

	known_vms=$(virsh -q list --all | awk '{ print $2 }')
	for known_vm in $known_vms; do
		if [[ $known_vm == $vm_name ]]; then
			ok='ok'
		fi
	done

	if [[ $ok != "ok" ]]; then
		echo "argument $vm_name not in virsh list, continue? (y/n)"
		read response
		if [[ $response != "y" ]]; then
			exit 2
		fi
	fi
	#empty ok just in case
	ok=''
	
	if ! virsh shutdown $vm_name; then
		echo failed to shutdown vm, attempting to undefine
	fi
	
	if ! virsh undefine $vm_name; then
		echo failed to undefine vm, attempting to remove from /etc/hosts
	fi
	
	if [[ -n $(grep $vm_name /etc/hosts 2>/dev/null) ]]; then
		hostbak=/tmp/hostsbak$RANDOM
		hostnew=/tmp/hostnew$RANDOM
		if cp /etc/hosts $hostbak; then
			if ! grep -v -e "$vm_name" /etc/hosts > $hostnew; then
				echo failed to remove /etc/hosts mapping, backup at $hostbak
			elif cp $hostnew /etc/hosts; then
				rm $hostbak
			else
				echo failed to copy new host file, backup at $hostbak
			fi
		fi
	else 
		echo did not find mapping in hosts file
	fi
	
	# remove lvm
	full_line="$(lvs --no-headings -o lv_name,vg_name 2>/dev/null | grep $vm_name )"
	if [[ -n  $full_line ]]; then
		echo $full_line
		vg_name="$(echo $full_line | awk '{print $2}')"
		if ! lvremove $vg_name"/"$vm_name; then
			echo failed to remove lvm
		fi
	else
		echo could not find lvm, remove manually if still there
	fi
done
