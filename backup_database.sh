#!/bin/sh
#
# Script to automate backup of Galaxy database
#
# Usage: backup_database.sh <db>
#
# <db> can be "production" or "devel"
#
if [ $# -ne 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
  echo "Usage: $0 production|devel"
  exit
fi
if [ "$1" != "production" ] && [ "$1" != "devel" ] ; then
  echo "Db must be either 'production' or 'devel'"
  exit 1
fi
echo Backuping $1 database
#
if [ $1 == production ] ; then
   PSQL_DB=galaxy_prod
   PSQL_USER=galaxy
   DB_DIR=production/database
elif [ $1 == devel ] ; then
   PSQL_DB=galaxy_dev
   PSQL_USER=galaxy_dev
   DB_DIR=devel/database
fi
#
# Dump Postgres DB
timestamp=`date +%Y%m%d%H%M%S`
pg_dump_file=${HOME}/database_backup/galaxy_db.${1}.${timestamp}.pg_dump
pg_dump_cmd="pg_dump -U $PSQL_USER $PSQL_DB"
echo "Running $pg_dump_cmd to $pg_dump_file"
$pg_dump_cmd > $pg_dump_file
#
# Rsync the database directory
db_backup_dir=${HOME}/database_backup/database.${1}.backup
rsync_cmd="rsync -av --delete-after ${HOME}/${DB_DIR}/ $db_backup_dir"
echo "Running $rsync_cmd"
$rsync_cmd
##
#

