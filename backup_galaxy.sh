#!/bin/sh
#
# Make a copy of Galaxy code base
#
# Usage: backup_galaxy.sh <galaxy-dir>
#
# Makes a timestamped copy of code in <galaxy-dir>
#
if [ $# -ne 1 ] || [ "$1" == "-h" ]  || [ "$1" == "--help" ] ; then
  echo "Usage: $0 <galaxy-dir>"
  exit
fi
if [ ! -d "$1" ] ; then
  echo ERROR $1 not a directory
  exit 1
fi
#
parent_dir=`dirname $1`
cd $parent_dir
echo In `pwd`
#
timestamp=`date +%Y%m%d%H%M%S`
galaxy_dir=`basename $1`
galaxy_backup_dir=backup.${galaxy_dir}.${timestamp}
rsync_cmd="rsync -av --exclude=/database --exclude=/eggs --exclude=paster.log --exclude=paster.id $galaxy_dir/ $galaxy_backup_dir"
echo $rsync_cmd
$rsync_cmd
##
#
