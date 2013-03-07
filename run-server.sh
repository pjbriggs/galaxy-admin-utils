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
echo Arguments: $@
#
# Check there's a run.sh file here
if [ ! -f run.sh ] ; then
    echo No run.sh file here
    exit 1
fi
#
# Check that the server exists in universe_wsgi.ini
if [ ! -f universe_wsgi.ini ] ; then
    echo No universe_wsgi.ini here
    exit 1
fi
server_exists=`grep "^\[server:$server\]" universe_wsgi.ini 2>/dev/null`
if [ -z "$server_exists" ] ; then
    echo No server called $server found in universe_wsgi.ini
    exit 1
fi
#
# Issue the command to the server process
echo Sending $@ to $server
sh run.sh --server-name=$server --pid-file=$server.pid --log-file=$server.log $@
echo Done
##
#