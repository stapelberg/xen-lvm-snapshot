#!/bin/sh
#
# © 2009-2012 Michael Stapelberg (see also: LICENSE)
#
# Cleanly unmounts and removes the mounted LVM snapshot which has before
# been mounted by mount-snapshot.sh
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

# The LVM path to our snapshot
SNAP_NAME=$(echo "$NAME" | sed -e 's,domu-,snap_,')
SNAP_PATH="/dev/mapper/$(echo "$NAME" | sed -e 's,/,-,; s,domu-,snap_,')"

mounted=$(awk "{ if (\$2 == \"/mnt/snap_${DOMU}\") { print \$1 } }" /proc/mounts)
if [ "${mounted}" = "" ]
then
	echo "Mountpoint /mnt/snap_${DOMU} not mounted, aborting..."
	exit 1
fi

echo "removing"
umount /mnt/snap_${DOMU}
rm -rf /mnt/snap_${DOMU}

# Remove the loop device
/sbin/kpartx -s -d "$SNAP_PATH"

# Workaround for http://bugs.debian.org/549691
/sbin/dmsetup remove "${SNAP_PATH}"
/sbin/dmsetup remove "${SNAP_PATH}-cow"

set +e
false
while [ $? -ne 0 ]; do
       /sbin/lvremove --verbose -f "${SNAP_NAME}"
       if [ $? -ne 0 ]; then
               ORIG=$(echo "$SNAP_NAME" | sed -e 's,/snap_,-domu--,g')
               echo "failed. SNAP_NAME = $SNAP_NAME, ORIG = $ORIG"
               dmsetup resume "$ORIG"
               false
       fi
done
