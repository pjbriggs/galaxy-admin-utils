#!/bin/sh
#
# add_tool.sh: add a tool to a basic local instance of Galaxy
# Peter Briggs, University of Manchester 2013
#
# Usage: add_tool.sh DIR TOOL.xml [ TOOL_WRAPPER ]
#
# DIR = directory where Galaxy instance was installed
#       by deploy_galaxy.sh
#
# Command line
if [ $# -lt 2 ] ||  [ $# -gt 3 ] ; then
    echo "Usage: $0 DIR TOOL.xml [ TOOL_WRAPPER ]"
    exit
fi
GALAXY_DIR=$1
TOOL_XML=$2
TOOL_WRAPPER=$3
#
# Components in Galaxy instance
local_tool_conf=$GALAXY_DIR/galaxy-dist/local_tool_conf.xml
if [ ! -f $local_tool_conf ] ; then
    echo "ERROR no file $local_tool_conf"
    exit 1
fi
local_tools_dir=$GALAXY_DIR/local_tools
if [ ! -d $local_tools_dir ] ; then
    echo "ERROR no directory $local_tools_dir"
    exit 1
fi
#
# Install tool files
tool_name=${TOOL_XML%.*}
tool_name=`basename $tool_name`
echo "Installing tool '$tool_name' in $GALAXY_DIR"
if [ ! -d $local_tools_dir/$tool_name ] ; then
    echo "Making tool subdirectory '$tool_name' for $TOOL_XML"
    mkdir $local_tools_dir/$tool_name
fi
/bin/cp -f $TOOL_XML $local_tools_dir/$tool_name
if [ ! -z "$TOOL_WRAPPER" ] ; then
    /bin/cp -f $TOOL_WRAPPER $local_tools_dir/$tool_name
fi
#
# Update the conf file
update_conf_file=`grep ${tool_name}.xml $local_tool_conf`
if [ -z "$update_conf_file" ] ; then
    echo "Updating local_tool_conf.xml"
    sed -i 's,<!--Add tool references here-->,<tool file=\"'"$tool_name"'\/'"$tool_name"'.xml\" \/>\n\t<!--Add tool references here-->,' $local_tool_conf
else
    echo "Tool already referenced in $local_tool_conf"
fi
#
# Finished
echo "Done - restart Galaxy to access the installed tool"
##
#
