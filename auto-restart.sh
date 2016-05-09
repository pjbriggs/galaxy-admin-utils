#!/bin/bash
#
# Automatically restart Galaxy on update
#
# Checks if any files have changed in specified dir
# since the last time this script was run and does
# rolling restart if yes
if [ $# -ne 2 ] ; then
    echo Usage: $(basename $0) GALAXY_DIR WATCH_DIR
    exit
fi
GALAXY_DIR=$1
WATCH_DIR=$2
if [ ! -d $WATCH_DIR ] ; then
    echo ERROR no directory $WATCH_DIR >&2
    exit 1
fi
# Reference file
reference=$WATCH_DIR/$(basename $0).watch
if [ -f $reference ] ; then
    updated=$(find $WATCH_DIR -newer $reference)
    if [ ! -z "$updated" ] ; then
	this_dir=$(pwd)
	cd $GALAXY_DIR
	$(dirname $0)/rolling-restart.sh
	cd $this_dir
    fi
fi
# Create/update the reference file
touch $reference
##
#

