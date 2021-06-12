#!/bin/bash

# check run as root
# TODO: rewrite as binary and use user id in file permissions to allow limited non-sudo usage. ROOT priviliges needed for lvm
if [ "$EUID" -ne 0 ]; then
	echo Must be run as root
	exit 0
fi

confloc="/opt/vm/conf/"$1
conf=$confloc"/"$1".conf"
cloudinitname="cloudinit"$( date +%s  )$(( RANDOM ))".iso"
USAGE="USAGE:\n$0 PARENT_VM NEW_VM\nLooks in $confloc"
newvm=$2

if [[ $# != 2 ]]; then
	echo wrong amount of arguments
	echo -e $USAGE
	exit 0
fi
if [ -f $conf ]; then
	if ! source $conf; then
		echo error sourcing file, check valid bash syntax in: $conf
	fi
elif [ ! -d $confloc ]; then
	echo directory $confloc does not exist
	exit 4
else
	echo could not find conf file in $conf
	echo -e $USAGE
	exit 4
fi

function cleanup_exit {
	#cleanup
	if [ -f /tmp/meta-data ]; then
		if ! rm -f /tmp/meta-data; then
			echo failed to cleanup meta-data file in /tmp
		fi
	fi
	if [ -f /tmp/user-data ]; then
		if ! rm -f /tmp/user-data; then
			echo failed to cleanup user-data file in /tmp
		fi
	fi
	if [ -f /tmp/$cloudinitname ]; then
		if ! rm -f /tmp/$cloudinitname; then
			echo failed to cleanup $cloudinitname file in /tmp
		fi
	fi
	if [[ $1 != 0 ]] && [[ -b $(dirname $rootdev 2>/dev/null)"/$newvm" ]]; then
		lvremove $(dirname $rootdev 2> /dev/null)"/$newvm"
	fi
	exit $1
}

echo -e "instance-id: $newvm\nlocal-hostname: $newvm" > /tmp/meta-data
touch /tmp/user-data
if ! genisoimage -output /tmp/$cloudinitname -volid cidata -joliet -rock "/tmp/meta-data" "/tmp/user-data" &> /dev/null; then
	echo Failed to create cloud init configuration
	cleanup_exit 7
fi

if [[ ! -b $rootdev ]]; then
	echo rootdev not a valid block device\nconf file: $conf
	cleanup_exit 3
elif [[ -n $newvm ]]; then
	if ! lvcreate -s $rootdev -n "$newvm" -ay -kn; then
		echo error creating snapshot
		cleanup_exit 5
	fi
	if [ -z $network ]; then
		network="default"
	fi
	if ! virt-install --name $newvm --memory 8192 --vcpus 4 --network network=$network --graphics none --noautoconsole --import --disk path=$(dirname $rootdev)"/$newvm" --cdrom /tmp/$cloudinitname; then
		echo error starting installation
		cleanup_exit 6
	fi
else
	echo -e $USAGE
	cleanup_exit 1
fi

# add hostname mapping to /etc/hosts
# yea I know, not a great implementation, dumpxml does not provide runtime ip addresses so this was the easiest alternative I could think of
timeStart=$SECONDS
while [[ -z $(sudo virsh domifaddr $newvm 2>/dev/null | sed -n '3p' | awk -F ' ' '{ print $4 }') ]]; do
	if (( $SECONDS - $timeStart > 300 )); then
		echo timed out waiting for ip address, /etc/hosts not updated
		cleanup_exit 0
	fi
done
ipaddr=$( sudo virsh domifaddr $newvm 2>/dev/null | sed -n '3p' | awk -F ' ' '{ print $4 }' | awk -F '/' '{ print $1 }')
if ! echo -e "$ipaddr\t$newvm" >> /etc/hosts; then
	echo failed to add entry to /etc/hosts file
	cleanup_exit 0
fi
echo added mapping to /etc/hosts

systemctl restart dnsmasq

cleanup_exit 0
