#!/bin/bash
#
# Automatically restart Galaxy on update
#
# Checks if any files have changed in specified dir
# since the last time this script was run and does
# rolling restart if yes
if [ $# -lt 2 ] ; then
    echo Usage: $(basename $0) GALAXY_DIR WATCH_DIR \[WATCH_DIR ...\]
    exit
fi
GALAXY_DIR=$1
# Loop over dirs to check
do_restart=
for WATCH_DIR in ${@:2} ; do
    if [ -z "$(echo $WATCH_DIR | grep ^/)" ] ; then
	# Assume relative path to GALAXY_DIR
	WATCH_DIR=$GALAXY_DIR/$WATCH_DIR
    fi
    if [ ! -d $WATCH_DIR ] ; then
	echo ERROR no directory $WATCH_DIR >&2
	continue
    fi
    # Reference file
    reference=$WATCH_DIR/$(basename $0).watch
    if [ -f $reference ] ; then
	updated=$(find $WATCH_DIR -newer $reference)
	if [ ! -z "$updated" ] ; then
	    do_restart=yes
	fi
    fi
    # Create/update the reference file
    touch $reference
done
# Perform a restart?
if [ ! -z "$do_restart" ] ; then
    cd $GALAXY_DIR
    $(dirname $0)/rolling-restart.sh
fi
##
#
