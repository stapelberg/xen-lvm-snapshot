#!/bin/sh
#
# © 2009-2011 Michael Stapelberg (see also: LICENSE)
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

# Create a snapshot of the domU with 1 GB of space for modifications while the
# backup is being run. If you have backups which take very long or if you
# constantly modify data, you need to adjust this value.
lvcreate -n snap_$DOMU -L 1G -s $NAME

# The path to our snapshot in the filesystem
SNAP_PATH="/dev/mapper/$(echo "$NAME" | sed -e 's,/,-,; s,domu-,snap_,')"
# The LVM path to our snapshot
SNAP_NAME=$(echo "$NAME" | sed -e 's,domu-,snap_,')

offset=$(parted -m "$SNAP_PATH" unit B print | awk -F : \
	'{ if ($5 == "ext3") { gsub("B", "", $2); print $2; } }')

echo "Mounting data partition at $offset"
# loop-mount the data partition inside LVM snapshot
losetup -o "${offset}" -f "${SNAP_PATH}"

# Get the name of the loop device which has been chosen by -f
LOOP=$(losetup -a | grep "(${SNAP_PATH})" -m1 | cut -d : -f 1)

# Run fsck.ext3 to restore the journal
fsck.ext3 -y "${LOOP}" || true

# Mount the file system
mkdir /mnt/snap_${DOMU}
mount "${LOOP}" /mnt/snap_${DOMU}
