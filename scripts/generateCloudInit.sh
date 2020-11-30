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
