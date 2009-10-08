#!/bin/sh
#
# © 2009 Michael Stapelberg
#

source $(dirname $0)/common.sh

ACTION="$1"
if [[ "${ACTION}" != "mount" && "${ACTION}" != "unmount" ]]
then
	echo "Syntax: $0 <mount|unmount>"
	echo "Calls the appropriate LVM snapshot script for mounting/unmounting"
	echo "all logical volumes with names starting with \"domu-\""
	exit 1
fi

LVS=$(lvs --separator / --noheadings -o vg_name,lv_name 2>&- | tr -d ' ' | grep '/domu-')
for LV in ${LVS}
do
	echo "Handling LV $LV"
	if [ "${ACTION}" = "mount" ]
	then
		$(dirname $0)/mount-snapshot.sh "${LV}"
	else
		$(dirname $0)/unmount-snapshot.sh "${LV}"
	fi
done
