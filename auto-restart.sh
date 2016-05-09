#!/bin/bash
#
# Automatically restart Galaxy on update
#
# Checks if any files have changed in specified dir
# since the last time this script was run and does
# rolling restart if yes
#
# Initialise
GRACE_PERIOD=1
#
# Handle command line
if [ $# -lt 2 ] ; then
    echo Usage: $(basename $0) GALAXY_DIR WATCH_DIR \[WATCH_DIR ...\]
    exit
fi
GALAXY_DIR=$1
WATCH_DIRS=
for d in ${@:2} ; do
    if [ -z "$(echo $d | grep ^/)" ] ; then
	# Assume relative path to GALAXY_DIR
	WATCH_DIR=$GALAXY_DIR/$d
    else
	WATCH_DIR=$d
    fi
    if [ ! -d $WATCH_DIR ] ; then
	echo ERROR no directory $WATCH_DIR >&2
	continue
    fi
    if [ -z "$WATCH_DIRS" ] ; then
	WATCH_DIRS=$WATCH_DIR
    else
	WATCH_DIRS="$WATCH_DIRS $WATCH_DIR"
    fi
done
# Loop over dirs to check
still_updating=
do_restart=
for WATCH_DIR in $WATCH_DIRS ; do
    # Reference file
    reference=$WATCH_DIR/$(basename $0).watch
    if [ -f $reference ] ; then
	# Look for updates since last check
	updated_since_last_check=$(find $WATCH_DIR -newer $reference)
	if [ ! -z "$updated_since_last_check" ] ; then
	    do_restart=yes
	fi
	# Also check nothing has been
	# updated in last minute
	updated_in_last_minute=$(find $WATCH_DIR -mmin $GRACE_PERIOD)
	if [ ! -z "$updated_in_last_minute" ] ; then
	    echo $updated_in_last_minute
	    still_updating=yes
	fi
    else
	# Create the reference file
	touch $reference
    fi
done
# Perform a restart
if [ -z "$still_updating" ] && [ ! -z "$do_restart" ] ; then
    # Update the reference files
    for WATCH_DIR in $WATCH_DIRS ; do
	touch $WATCH_DIR/$(basename $0).watch
    done
    # Do the restart
    cd $GALAXY_DIR
    $(dirname $0)/rolling-restart.sh
fi
##
#
