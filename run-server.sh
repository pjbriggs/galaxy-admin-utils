#!/bin/sh
#
# run-server.sh: interact with a single Galaxy server process
# Peter Briggs, University of Manchester 2013
#
# Usage: run-server.sh SERVER args...
#
# Must be executed from the directory where the run.sh and
# universe_wsgi.ini files are located
#
# Can be used to interact with a single Galaxy server process
# in a load-balanced set-up where there are multiple
# co-operating servers e.g. web0, web1, manager, handler0 etc
#
# For example to stop handler1 do
#
# $ sh run-server.sh web0 --stop-daemon
#
# NB also supports a --restart-daemon option which issues
# --stop-daemon/--daemon commands one after the other
#
echo Interact with a single Galaxy server process
#
# Get server name
if [ -z "$1" ] ; then
    echo Usage: $0 SERVER
    exit 1
else
    server=$1
    shift
fi
#
# Check arguments were supplied
if [ $# -eq 0 ] ; then
    echo No arguments supplied
    exit 1
fi
#
# Look for --restart-daemon
restart_daemon=
if [ "$1" == "--restart-daemon" ] ; then
    restart_daemon=yes
fi
#
# Locate configuration file
echo -n Looking for configuration file...
for conf in universe_wsgi.ini config/galaxy.ini ; do
    config_file=$conf
    if [ -f $config_file ] ; then
	echo $config_file
	break
    else
	config_file=
    fi
done
if [ -z "$config_file" ] ; then
    echo not found
    echo ERROR no config file found >&2
    exit 1
fi
#
# Check there's a run.sh file here
if [ ! -f run.sh ] ; then
    echo No run.sh file here
    exit 1
fi
#
# Check that the server exists in config file
server_exists=$(grep "^\[server:$server\]" $config_file 2>/dev/null)
if [ -z "$server_exists" ] ; then
    echo No server called $server found in $config_file
    exit 1
fi
#
# Explicitly ensure GALAXY_RUN_ALL is set to a null value
export GALAXY_RUN_ALL=
#
# Issue the command to the server process
function call_server() {
    local server=$1
    shift
    echo Sending $@ to $server
    sh run.sh --server-name=$server --pid-file=$server.pid --log-file=$server.log $@
}
if [ ! -z "$restart_daemon" ] ; then
    echo Restarting $server
    call_server $server --stop-daemon
    call_server $server --daemon
else
    call_server $server $@
fi
echo Done
##
#
