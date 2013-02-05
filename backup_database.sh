#!/bin/sh
#
# Script to automate backup of Galaxy database
#
# Usage: backup_database.sh [--dry-run] GALAXY_DIR
#
# Command line
dry_run=
if [ "$1" == "--dry-run" ] ; then
    dry_run=yes
    shift
fi
if [ -z "$1" ] ; then
    echo "Usage: $0 [--dry-run] DIR"
    exit
fi
GALAXY_DIR=$1
#
# Look for universe_wsgi.ini and extract SQL database  details
#
# Formats are:
# sqlite:///./database/universe.sqlite?isolation_level=IMMEDIATE
# postgres://user:password@localhost:5432/database
universe_wsgi=$GALAXY_DIR/universe_wsgi.ini
if [ ! -f $universe_wsgi ] ; then
    echo "Can't find $universe_wsgi.ini"
    exit 1
fi
database_connection=`grep "^database_connection" $universe_wsgi | tail -1 | cut -f2- -d"="`
if [ -z "$database_connection" ] ; then
    # Capture the default which is commented out
    database_connection=`grep "^#database_connection" $universe_wsgi | tail -1 | cut -f2- -d"="`
fi
# Uncomment for testing
##database_connection="database_connection = postgres://galaxy:secret@127.0.0.1:5432/galaxy_prod"
database_connection=`echo $database_connection | cut -f2- -d"="`
echo "$database_connection"
db_type=`echo $database_connection | cut -d":" -f1`
echo "$db_type"
if [ "$db_type" == "postgres" ] ; then
    # Extract user, password and db name
    echo "Postgres database engine"
    psql_db=`echo $database_connection | cut -f4 -d"/"`
    psql_user=`echo $database_connection | cut -f3 -d"/" | cut -f1 -d":"`
    psql_passwd=`echo $database_connection | cut -f3 -d"/" | cut -f2 -d":" | cut -f1 -d"@"`
    psql_host=`echo $database_connection | cut -f3 -d"/" | cut -f2 -d":" | cut -f2 -d"@"`
    psql_port=`echo $database_connection | cut -f3 -d"/" | cut -f3 -d":"`
    echo "Database: $psql_db"
    echo "User    : $psql_user"
    echo "Password: $psql_passwd"
    echo "Host    : $psql_host"
    echo "Port    : $psql_port"
else
    echo "Backup for '$db_type' not implemented"
    echo "Stopping"
    exit
fi
#
# Locate the files part of the database
file_path=`grep "^#\?file_path" $universe_wsgi | cut -f2- -d"="`
file_path=`echo $file_path`
DB_DIR=$GALAXY_DIR/$file_path
echo "Database files: $DB_DIR"
echo "Dry run $dry_run"
#
# Backup the SQL database
timestamp=`date +%Y%m%d%H%M%S`
if [ "$db_type" == "postgres" ] ; then
    # Set up destination for Postgres dump
    pg_dump_file=galaxy_db.${timestamp}.pg_dump
    # Set up and run the command
    pg_dump_cmd="pg_dump -h $psql_host -p $psql_port -U $psql_user $psql_db"
    echo "Dumping the SQL database contents to $pg_dump_file"
    export PGPASSWORD=$psql_passwd
    echo "$pg_dump_cmd > $pg_dump_file"
    if [ -z "$dry_run" ] ; then
	$pg_dump_cmd > $pg_dump_file
    fi
fi
#
# Rsync the database files
db_backup_dir=galaxy_db_files.backup
rsync_cmd="rsync -av --delete-after ${DB_DIR}/ $db_backup_dir"
echo "Running $rsync_cmd"
if [ -z "$dry_run" ] ; then
    $rsync_cmd 2>&1 > galaxy_db_files.backup.${timestamp}.log
    du -sh $db_backup_dir
fi
echo "Done"
exit
##
#
