#!/bin/sh
#
# Script to make a 'snapshot' of a Galaxy instance
#
# Usage: snapshot_galaxy.sh GALAXY_DIR SNAPSHOT_DIR [NAME]
#
# A snapshot is simply a complete copy of the contents of a
# Galaxy installation directory, which is assumed to
# contain 'galaxy-dist' plus tool directories etc.
#
# Snapshot copies are stored in timestamped directories.
# Specifying an optional NAME allows an arbitrary string
# to be appended to help with identification later.
#
# To restore simply copy the files from the snapshot
# directory using 'cp -a'.
#
# It is not suitable for use with large installations,
# or those using a non-Sqlite database.
#
function full_path() {
    local curr_dir=$(pwd)
    cd $1
    echo $(pwd)
    cd $curr_dir
}
#
# Process command line
if [ -z "$1" ] ; then
    echo "Usage: $0 GALAXY_DIR SNAPSHOT_DIR [NAME]"
    exit
fi
GALAXY_DIR=$(full_path $1)
SNAPSHOT_DIR=$2
SNAPSHOT_NAME=$3
if [ ! -z "$SNAPSHOT_NAME" ] ; then
    SNAPSHOT_NAME="."$SNAPSHOT_NAME
fi
#
# Check for galaxy-dist
if [ ! -d $GALAXY_DIR/galaxy-dist ] ; then
    echo ERROR no 'galaxy-dist' dir found under $GALAXY_DIR >&2
    exit 1
fi
#
# Sort out destination directory for snapshots
if [ ! -e "$SNAPSHOT_DIR" ] ; then
    echo -n Making top level snapshot directory: $SNAPSHOT_DIR...
    mkdir -p $SNAPSHOT_DIR
    echo done
fi
#
# Check that snapshots are not under galaxy dir
SNAPSHOT_DIR=$(full_path $SNAPSHOT_DIR)
if [ -z "$(echo $SNAPSHOT_DIR | grep -v $GALAXY_DIR)" ] ; then
    echo ERROR snapshot dir is subdir of galaxy dir >&2
    exit 1
fi
# Make timestamped snapshot subdir
snapshot_dir=$SNAPSHOT_DIR/$(basename $GALAXY_DIR)/snapshot-$(date +%s-%Y%m%d)$SNAPSHOT_NAME
if [ -d $snapshot_dir ] ; then
    echo ERROR snapshot dir $snapshot_dir already exists >&2
    exit 1
fi
echo -n Making $snapshot_dir...
mkdir -p $snapshot_dir
echo done
# Copy everything
echo -n Copying...
cp -a $GALAXY_DIR/* $snapshot_dir
if [ $? -ne 0 ] ; then
    echo FAILED
    echo ERROR cp returned nonzero status >&2
    exit 1
else
    echo done
    du -sh $snapshot_dir
fi
exit 0
##
#

