#!/bin/sh
#
# rolling-restart.sh: restart multiple Galaxy processes in a "rolling" fashion
# Peter Briggs, University of Manchester 2013
#
# Usage: rolling-restart.sh
#
# Must be executed from the directory where the run.sh and universe_wsgi.ini files
# are located
#
# Stops and starts each of the servers listed in universe_wsgi.ini in turn (except
# for "manager", which must be restarted explicitly using e.g. run-server.sh),
# waiting for each one to come back online before restarting the next.
#
# For set ups with multiple handlers and web servers this should mean that Galaxy
# remains available to end users throughout the restart process.
#
servers=$(grep "^\[server:" universe_wsgi.ini | sed 's/\[server:\(.*\)\]/\1/g')
for s in $servers ; do
    # Restart each server in turn (except the manager)
    if [ $s != "manager" ] ; then
	echo Restarting $s
	sh run.sh --server-name=$s --pid-file=$s.pid --log-file=$s.log --stop-daemon
	sh run.sh --server-name=$s --pid-file=$s.pid --log-file=$s.log --daemon
	# Wait until it's actively serving again
	keep_checking=yes
	echo -n "Waiting for $s "
	while [ ! -z "$keep_checking" ] ; do
	    if [ -f "$s.pid" ] ; then
		pid=`cat $s.pid 2>/dev/null`
		if [ ! -z "$pid" ] && [ -f "$s.log" ] ; then
		    serving=`grep -A 1 "^Starting server in PID $pid" $s.log | grep "^serving on"`
		    if [ ! -z "$serving" ] ; then
			echo " back online"
			keep_checking=
		    fi
		fi
	    fi
	    if [ ! -z "$keep_checking" ] ; then
		# Wait before checking again
		echo -n .
		sleep 10
	    fi
	done
    else
	echo "$s will not be restarted"
    fi
done
##
#