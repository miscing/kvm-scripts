#!/bin/bash

USAGE="$0 vm_name"

if (( $# != 1 )); then
	echo -e $USAGE
	exit 0
fi

vm_name="$1"

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
