#!/bin/bash

name="cloudinit"$(( RANDOM ))".iso"

if [[ -d $1 ]]; then
	if genisoimage -verbose -output /tmp/$name -volid cidata -joliet -rock $1/meta-data $1/user-data &> /dev/null; then
		echo $name
	fi
else
	if genisoimage -verbose -output /tmp/$name -volid cidata -joliet -rock ./meta-data ./user-data &> /dev/null; then
		echo $name
	fi
fi
