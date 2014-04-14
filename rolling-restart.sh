#!/bin/sh
#
# rolling-restart.sh: restart multiple Galaxy processes in a "rolling" fashion
# Peter Briggs, University of Manchester 2013
#
# Usage: rolling-restart.sh
#
# Must be executed from the directory where the run.sh and universe_wsgi.ini files
# are located, or specify the paths to your galaxy directory 
#
# Stops and starts each of the servers listed in universe_wsgi.ini in turn (except
# for "manager", which must be restarted explicitly using e.g. run-server.sh),
# waiting for each one to come back online before restarting the next.
#
# For set ups with multiple handlers and web servers this should mean that Galaxy
# remains available to end users throughout the restart process.
#
# Thanks to Brad Langhorst https://github.com/bwlang for additional improvements/
# generalisation.
#
# Change these values to match your installation
GALAXY_PATH=.
LOG_PATH=.
PID_PATH=.
# Collect list of servers
servers=$(grep "^\[server:" $GALAXY_PATH/universe_wsgi.ini | sed 's/\[server:\(.*\)\]/\1/g')
for s in $servers ; do
    # Restart each server in turn (except the manager)
    if [ $s != "manager" ] ; then
	echo Restarting $s
	pid_file="$PID_PATH/$s.pid"
	log_file="$LOG_PATH/$s.log"
	cmd="$GALAXY_PATH/run.sh"
	args="--server-name=$s --pid-file=$pid_file --log-file=$log_file"
	sh $cmd $args --stop-daemon
	if [ -f "$pid_file" ] ; then
	    echo STDERR "Permission error? PID file still exists even after running $cmd $args --stop-daemon "
	    exit 1
	fi
	#echo "running $cmd $args --daemon"
	sh $cmd $args --daemon
	# Wait until it's actively serving again
	keep_checking=yes
	echo -n "Waiting for $s "
	while [ ! -z "$keep_checking" ] ; do
	    if [ -f "$pid_file" ] ; then
		pid=`cat "$pid_file" 2>/dev/null`
		#echo new pid: $pid
		if [ ! -z "$pid" ] &&  [ -f "$log_file" ] ; then
		    serving=`grep -A 1 "^Starting server in PID $pid" $log_file | grep "^serving on"`
		    if [ ! -z "$serving" ] ; then
			echo " back online"
			keep_checking=
		    fi
		fi
	    fi
	    if [ ! -z "$keep_checking" ] ; then
		# Wait before checking again
		echo -n .
		sleep 5
	    fi
	done
    else
	echo "$s will not be restarted"
    fi
done
##
#
