DEF_NET="devel"
DEF_NAME="intra"
USAGE="$0 [network_name] [vm_name] \ndefault:\n\tname: ${DEF_NAME}\n\tnetwork: ${DEF_NET}"

for arg in "$@"; do
	if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
		echo -e $USAGE
		exit 1
	fi
done
if [[ $# > 2 ]]; then
	echo -e $USAGE
	exit 1
fi
if [[ $# == 2 ]]; then
	NET_NAME="$1"
	VM_NAME="$2"
elif [[ $# == 1 ]]; then
	VM_NAME="$DEF_NAME"
	NET_NAME="$1"
else
#	if [[ -f .cur_number ]]; then
#		num=$(cat .cur_number)
#	else
#		num=0
#	fi
	VM_NAME="${DEF_NAME}"
	NET_NAME="$DEF_NET"
fi
echo -e "using settings:\n\tnetwork: ${NET_NAME}\n\tvm name: ${VM_NAME}":
read -p "continue?" -n1 -r -t 10
echo
if [[ $REPLY =~ ^[Yy]$ ]];then

	IGNITION_CONFIG="/var/lib/libvirt/images/${VM_NAME}.ign"
	IMAGE="/var/lib/libvirt/images/fedora-coreos-34.x86_64.qcow2"

	function cleanup {
		#echo $num > .cur_number
		test -f $IGNITION_CONFIG && rm $IGNITION_CONFIG
	}

	if ! jq --arg vm "data:,$VM_NAME" '.storage.files[0].contents.source = $vm' ignition.ign > $IGNITION_CONFIG; then
		echo "Failed to add hostname to ignition file"
		cleanup
		exit 2
	fi

	echo "using ignition file: $IGNITION_CONFIG"

	# stats
	RAM_MB="10240"
	VCPUS="4"
	DISK_GB="30"

	if ! virt-install --connect qemu:///system -n "${VM_NAME}" -r "${RAM_MB}" --vcpus "$VCPUS" --os-variant=fedora31 \
		--network network=$NET_NAME \
		--import --noautoconsole --graphics=none --disk "size=${DISK_GB},backing_store=${IMAGE}" \
		--disk "size=50" \
		--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
	then
		echo failed to install runner
		cleanup
		exit 4
	fi
	#echo $(( $num + 1 )) > .cur_number
	echo installed runner succesfully, no dns mapping
fi
# TODO: Wait for VM to initialize, shutdown and remove ignition file
