#!/bin/bash

USAGE="$0 vm_name"

if (( $# != 1 )); then
	echo -e $USAGE
	exit 0
fi

if ! virsh shutdown $1; then
	echo failed to shutdown vm, attempting to undefine
fi

if ! virsh undefine $1; then
	echo failed to undefine vm, exiting
	exit 1
fi

if [[ -n $(grep $vm_name /etc/hosts 2>/dev/null) ]]; then
	hostbak=/tmp/hostsbak$RANDOM
	if cp /etc/hosts $hostbak; then
		if ! grep -v -e "$vm_name" /etc/hosts >> /etc/hosts; then
			echo failed to remove /etc/hosts mapping, backup at $hostbak
		else
			rm $hostbak
		fi
	fi
fi

echo vm removed
echo remove lvm manually
