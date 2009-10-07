# fail as soon as a statement returns a non-zero value
set -e

# Suppress warnings about open file descriptors. We want to keep our stderr
# clean so that we can monitor it without getting unimportant warnings
export LVM_SUPPRESS_FD_WARNINGS=1
