#!/bin/bash

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
	lv_name="$(lvs --reportformat=json -o lv_name,vg_name | jq --arg name $vm_name -r '.report[0].lv[] | select(.lv_name==$name) | .lv_name')"
	vg_name="$(lvs --reportformat=json -o lv_name,vg_name | jq --arg name $vm_name -r '.report[0].lv[] | select(.lv_name==$name) | .vg_name')"
	echo $lv_name $vg_name $vm_name
	if [[ -n $lv_name && -n $vg_name ]];then
		echo "Delete $vg_name/$lv_name? (y/N)"
		read response
		if [[ $response != "y" ]]; then
			exit 2
		fi
		if ! lvremove $vg_name"/"$lv_name; then
			echo failed to remove lvm
		fi
	fi
	# look for snapshots
	regex="^$vm_name-\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}"
	snaps=$(lvs --reportformat=json -o lv_name,vg_name | jq -r --arg re $regex '.report[0].lv[].lv_name | match($re) | .string')
	vg_name="$(lvs --reportformat=json -o lv_name,vg_name | jq --arg name $(echo $snaps | awk '{print $1}') -r '.report[0].lv[] | select(.lv_name==$name) | .vg_name')"
	if [[ -n $snaps ]]; then
		echo "found snapshots:"
		echo $snaps
		echo "Delete? (y/N)"
		read response
		if [[ $response != "y" ]]; then
			exit 2
		fi
		echo VG: $vg_name
		echo LV: $lv_name
		lvs --reportformat=json -o lv_name,vg_name | jq -r --arg re $regex '.report[0].lv[].lv_name | match($re) | .string' | xargs -l -I '{}' lvremove $vg_name/{}
	fi
done
