#!/bin/sh
#
# Script to locate GALAXY_SLOTS within a toolshed repository
#
# Given the path to a toolshed repo, hg clones it and then
# searches XML files for the pattern \${GALAXY_SLOTS:-...}
#
# If any references are found then this gives an indication
# of whether a tool operates in a multicore fashion (and
# how many cores might be assigned). It also reports the
# tool id (useful for assigning explicit job runners in
# job_conf.xml).
#
# Examples:
#
# get_galaxy_slots.sh https://pjbriggs@toolshed.g2.bx.psu.edu/repos/devteam/tophat
# get_galaxy_slots.sh https://pjbriggs@toolshed.g2.bx.psu.edu/repos/iuc/vsearch
#
if [ -z "$1" ] ; then
    echo Usage: $(basename $0) TOOLSHED_REPO
    exit
fi
#
# Get name of tool repo
repo=$1
#
# Make a working dir and switch to it
wd=$(mktemp -d)
pushd $wd
#
# Fetch the tool files
echo -n Cloning $repo...
hg clone $repo >/dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo FAILED
    ##popd
    ##rm -rf $wd
    echo ERROR cloning repo $repo >&2 
    exit 1
fi
echo done
#
# Examine .xml files looking for $GALAXY_SLOTS
echo -n Searching for GALAXY_SLOTS...
repo_dir=$(basename $repo)
files=$(find $repo_dir -name "*.xml" -exec grep -l "\${GALAXY_SLOTS:-" {} \;)
echo done
#
# Report what was found
if [ ! -z "$files" ] ; then
    for f in $files ; do
	echo ${f}:
	# Get tool id
	tool_id=$(grep "<tool" $f | grep -o -e id=\"\[^\"\]*\")
	if [ ! -z "$tool_id" ] ; then
	    echo "*" $tool_id
	else
	    echo "* WARNING no tool id detected"
	fi
	for m in "$(grep '\${GALAXY_SLOTS:-' $f)" ; do
	    echo "*" $m
	done
    done
else
    echo No references to GALAXY_SLOTS found
fi
#
# Finished
popd
##rm -rf $wd/$repo_name
##rmdir $wd
##
#
