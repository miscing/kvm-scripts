#!/bin/bash


lvmbackuplist=
mountpoint=
snapshotlist=

function sendmail {
}

while IFS=' ' read sourcelvm || [[ -n "$sourcelvm" ]]; do

	lvm_name=$(echo $sourcelvm | cut -d '/' -f 2)
	vg_name=$(echo $sourcelvm | cut -d '/' -f 1)
	currenttime=$(date +"%Y-%m-%d-%H-%M")
	fullname=$lvm_name'-'$currenttime

	#Print existing snapshots to a temp file
	lvm lvs |grep $lvm_name'-' |cut -d ' ' -f 3 >> $snapshotlist
	if [ ! -s $snapshotlist ]; then
		rm $snapshotlist
		/usr/sbin/sendmail -i 
Subject: LVM Snapshots
To:
No snapshots to backup =/.
MAIL_END
		continue
	fi #check that there are snapshots

	# Find the oldest lvm in list
	sort $snapshotlist -o $snapshotlist </dev/null
	oldest=$(grep -m 1 $lvm_name $snapshotlist)

	# Activate snapshot
	lvchange -K -ay $vg_name'/'$oldest </dev/null
	if [[ $? != 0 ]]; then
		/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
lvchange failed to activate snapshot.
MAIL_END
		exit 1
	fi

	# find name of snapshot in /dev/mapper directory
	device_name_in_directory=$vg_name'-'$(grep -m 1 $lvm_name $snapshotlist | sed -e 's/-/--/g' -e 's/\//-/')

	if [[ -b /dev/mapper/$device_name_in_directory ]]; then
		dd bs=4M if=/dev/mapper/$device_name_in_directory of=/mnt/backup/virtual_machines/$fullname.img
		if [[ $? != 0 ]]; then
			/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
dd failed something biiig trouble.
MAIL_END
			exit 1
		fi
	else
		/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
Did not find device.
MAIL_END
		exit 1
	fi # Copy the disk, this step takes the longest

	# Deactivate snapshot
	lvchange -an $vg_name'/'$oldest
	if [[ $? != 0 ]]; then
		/usr/sbin/sendmail -i 
Subject: LVM Snapshots
To:
Failed to deactivate snapshot. Check manually, no auto-fix.
MAIL_END
	fi

	# Delete old backup if there are more than one file per lvm
	while [[ 1 < $(find /mnt/backup/virtual_machines/ -name $lvm_name'*'|wc -l) ]]; do
		# find oldest in folder
		oldest_backup="$(find /mnt/backup/virtual_machines/ -name $lvm_name'*'| sort| head -n 1)"
		rm $oldest_backup
		if [[ $? != 0 ]]; then
			/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
failed to delete old backup.
MAIL_END
			exit 1
		fi
	done

	# delete temp file
	if [[ -e $snapshotlist ]]; then
		rm $snapshotlist
	fi

	# generic check that file exists and there is only one
	if [[ -f /mnt/backup/virtual_machines/$fullname.img && $(find /mnt/backup/virtual_machines/ -name $lvm_name'*'|wc -l) == 1 ]]; then
		/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
Backup of $sourcelvm made. Everything in order
MAIL_END

	else
		/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
Something failed. Ending prematurely.
MAIL_END
		exit 1
	fi


done < $lvmbackuplist
if [[ -e $snapshotlist ]]; then
	rm $snapshotlist
fi
if [[ $? != 0 ]]; then
	/usr/sbin/sendmail -i 
Subject:LVM Backup
To:
Temp file failed to be removed.
MAIL_END
fi


