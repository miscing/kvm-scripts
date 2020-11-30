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
