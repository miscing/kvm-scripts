#!/bin/bash 
USAGE="$0 [vm_name] [network_name]"


if [[ $# > 2 ]]; then
	echo -e $USAGE
	exit 1
fi

if [[ $# == 2 ]]; then
	VM_NAME="$1"
	NET_NAME="$2"
elif [[ $# == 1 ]]; then
	VM_NAME="$1"
	NET_NAME="prod"
else
	if [[ -f .cur_number ]]; then
		num=$(cat .cur_number)
	else
		num=0
	fi
	VM_NAME="coreos$num"
	NET_NAME="prod"
fi

function cleanup {
	rm ignition.ign
	test -f /var/lib/libvirt/images/ignition.ign && rm /var/lib/libvirt/images/ignition.ign
}

if ! jq --arg vm "data,$VM_NAME" '.storage.files[0].contents.source = $vm' ignition.ign.template > ignition.ign; then
	echo "Failed to add hostname to ignition file"
	cleanup
	exit 2
fi

if ! cp ./ignition.ign /var/lib/libvirt/images/ignition.ign; then
	echo failed to copy ignition file
	cleanup
	exit 3
fi

IGNITION_CONFIG="/var/lib/libvirt/images/ignition.ign"
IMAGE="/var/lib/libvirt/images/fedora-coreos.x86_64.qcow2"
echo "using ignition file: ${IGNITION_CONFIG}"

# stats
RAM_MB="10240"
VCPUS="4"
DISK_GB="30"

if ! virt-install --connect qemu:///system -n "${VM_NAME}" -r "${RAM_MB}" --vcpus "$VCPUS" --os-variant=fedora31 \
	--network network=$NET_NAME \
	--import --noautoconsole --graphics=none --disk "size=${DISK_GB},backing_store=${IMAGE}" \
	--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
then
	echo failed to install runner
	cleanup
	exit 4
fi
echo $(( $num + 1 )) > .cur_number
rm /var/lib/libvirt/images/ignition.ign
echo installed runner succesfully, no dns mapping
