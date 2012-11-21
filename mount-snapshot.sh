#!/bin/sh
#
# © 2009-2012 Michael Stapelberg (see also: LICENSE)
#
# This script mounts the first data partition inside the logical volume (that
# is, the LV is expected to contain a partition table) given as parameter.
#
# The name of the LV must begin with "domu-".
#

. $(dirname $0)/common.sh

NAME="$1"
if [ -z "${NAME}" ]
then
	echo "Syntax: $0 <lvm-path>"
	echo "Example: $0 in.zekjur.net/domu-infra"
	exit 1
fi

# Reduce the name from vg/domu-<name> to <name>
DOMU=$(echo "$NAME" | sed 's,[^/]*/domu-,,g')

if [ -e "/mnt/snap_${DOMU}" ]
then
	echo "Mountpoint /mnt/snap_${DOMU} already exists, not touching..."
	exit 1
fi

# Create a snapshot of the domU with 5 GB of space for modifications while the
# backup is being run. If you have backups which take very long or if you
# constantly modify data, you need to adjust this value.
/sbin/lvcreate -n snap_$DOMU -L 5G -s $NAME

# The path to our snapshot in the filesystem
SNAP_PATH="/dev/mapper/$(echo "$NAME" | sed -e 's,/,-,; s,domu-,snap_,')"
/sbin/kpartx -s -a "$SNAP_PATH"
/sbin/fsck -y "${SNAP_PATH}1" || true
mkdir /mnt/snap_${DOMU}
mount "${SNAP_PATH}1" "/mnt/snap_${DOMU}"
