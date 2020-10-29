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


USAGE="$0 [vm_name]"

#TODO: running runner names, use next free runner-[001-999]

if [[ $# == 1 ]]; then
	VM_NAME="$1"
else
	VM_NAME="runner"
fi

IGNITION_CONFIG="./ignition.ign"
IMAGE="../../os/fedora/fedora-coreos.x86_64.qcow2"
IGNITION_CONFIG="$(realpath $IGNITION_CONFIG)"
IMAGE="$(realpath $IMAGE)"
echo "using ignition file: ${IGNITION_CONFIG}"

# stats
RAM_MB="8192"
VCPUS="2"
DISK_GB="10"

if virt-install --connect qemu:///system -n "${VM_NAME}" -r "${RAM_MB}" --vcpus "$VCPUS" --os-variant=fedora31 \
        --network network=runners \
        --import --noautoconsole --graphics=none --disk "size=${DISK_GB},backing_store=${IMAGE}" \
        --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
then echo installed runner succesfully, no hosts mapping
else
	echo failed to install runner
fi

