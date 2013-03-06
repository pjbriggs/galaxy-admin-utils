#!/bin/sh
#
# Check status of Galaxy servers
cwd=`pwd`
echo "Status of galaxy running from $cwd"
echo 
servers=
all_active=yes
galaxy_error_state=
pid_files=`ls *.pid 2>/dev/null`
for f in $pid_files ; do
   server=${f%%.*}
   servers="$servers $server"
   pid=`cat $f`
   status=`ps --pid $pid --noheaders`
   if [ ! -z "$status" ] ; then
      status=Running
      if [ -f $server.log ] ; then
         serving=`grep "^Starting server in PID $pid" $server.log -A 1 | grep "^serving on"`
         if [ ! -z "$serving" ] ; then
	    port=`echo $serving | cut -d: -f3`
            status="Active (port $port)"
         fi
      fi
      if [ "$status" != "Active" ] ; then
         all_active=
      fi
   else
      status="Not running"
      galaxy_error_state=yes
      all_active=
   fi
   echo Server $server$'\t'PID $pid$'\t'Status $status
done
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
