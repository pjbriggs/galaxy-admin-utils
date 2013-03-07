#!/bin/sh
#
# galaxy_status.sh: monitor status of Galaxy server processes
# Peter Briggs, University of Manchester 2013
#
# Usage: galaxy_status.sh
#
# Must be executed from the directory where the .pid and .log
# files for the Galaxy server processes are being written
#
# Use "watch galaxy_status.sh" to monitor Galaxy
#
# Announce location
cwd=`pwd`
echo "Status of galaxy running from $cwd"
echo 
#
# Initialise flag variables
servers=
all_active=yes
galaxy_error_state=
#
# Collect PID files for server processes
pid_files=`ls *.pid 2>/dev/null`
#
# Check status of each process
# - PID must be active (indicates server process is running)
# - log file must announce that server is listening (indicates
#   server process is active)
#
for f in $pid_files ; do
   server=${f%%.*}
   servers="$servers $server"
   pid=`cat $f`
   status=`ps --pid $pid --noheaders 2>/dev/null`
   if [ ! -z "$status" ] ; then
      status=Running
      is_active=
      if [ -f $server.log ] ; then
         serving=`grep "^Starting server in PID $pid" $server.log -A 1 | grep "^serving on"`
         if [ ! -z "$serving" ] ; then
	    port=`echo $serving | cut -d: -f3`
	    is_active=yes
            status="Active (port $port)"
         fi
      fi
      if [ -z "$is_active" ] ; then
         # At least one server is inactive
         all_active=
      fi
   else
      status="Not running"
      galaxy_error_state=yes
      all_active=
   fi
   echo Server $server$'\t'PID $pid$'\t'Status $status
done
#
# Summarise status of Galaxy based on status of individual
# server processes
echo 
if [ -z "$servers" ] ; then
   echo No servers running
elif [ -z "$galaxy_error_state" ] ; then
   echo -n "All servers running"
   if [ "$all_active" == "yes" ] ; then
     echo " and active"
   else
     echo
   fi
else
   echo One or more servers in error state
fi 
##
#
