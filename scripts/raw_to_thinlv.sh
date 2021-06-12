#!/bin/bash

set -e

USAGE="$0 raw_image_path target_lvm_name"


if [[ -f "$1" ]] && [[ -n "$2" ]];then
	if lvs fast/$2 &>/dev/null ; then
		echo "lvm exists, delete it first"
		exit 1
	fi
	rawImg=$(readlink -f $1)
	size=$(stat --printf %s $rawImg)
	if [[ 0 != $(expr $size % 512) ]]; then
		while [[ 0 != $(expr $size % 512) ]]; do
			size=$(expr $size + 1)
		done
		echo "not a multiple of 512, rounding to: $size"
	fi
	echo creating $size thinlvm
	lvcreate -n $2 --thinpool fastpool -V $size'b' fast
	dd bs=4M if=$rawImg of=/dev/fast/$2 status=progress
else
	echo $USAGE
fi
