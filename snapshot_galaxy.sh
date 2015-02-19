#!/bin/sh
#
# Script to make a 'snapshot' of a Galaxy instance
#
# Usage: snapshot_galaxy.sh [options] GALAXY_DIR SNAPSHOT_DIR [NAME]
#
# A snapshot is simply a complete copy of the contents of a Galaxy
# installation directory, which is assumed to contain 'galaxy-dist' plus
# tool directories etc.
#
# Snapshot copies are stored in timestamped directories.  Specifying an
# optional NAME allows an arbitrary string to be appended to help with
# identification later.
#
# To restore, copy the files from the appropriate snapshot directory
# using 'cp -a'.
#
# Known issues:
# 1. If the database is Postgresql then the SQL will be dumped to file,
#    and will need to be reloaded in order to restore the database.
# 2. If 'file_path' points to a directory outside the the Galaxy dir
#    then the files database will not be copied unless the
#    --include-external option is specified.
#
function usage() {
    echo "Usage: $(basename $0) [options] GALAXY_DIR SNAPSHOT_DIR [NAME]"
    echo 
    echo "Creates a time-stamped 'snapshot' copy of GALAXY_DIR under"
    echo "SNAPSHOT_DIR. Optional argument NAME is an arbitrary string"
    echo "which is appended to the snapshot directory name as an aide-"
    echo "memoire."
    echo 
    echo "Options:"
    echo "  --include-external  Copy files component of database if"
    echo "                      not under GALAXY_DIR"
    echo 
}
function full_path() {
    local curr_dir=$(pwd)
    cd $1
    echo $(pwd)
    cd $curr_dir
}
function is_subdir() {
    if [ -z "$(echo $1 | grep ^/)" ] || [ -z "$(echo $1 | grep -v $2)" ] ; then
	echo yes
    else
	echo 
    fi
}
#
# Process command line
if [ -z "$1" ] ; then
    usage
    exit
fi
while [ ! -z "$(echo $1 | grep ^-)" ] ; do
    case "$1" in
	-h|--help)
	    usage
	    exit
	    ;;
	--include-external)
	    include_external=yes
	    ;;
	*)
	    echo ERROR: unrecognised option $1 >&2
	    exit 1
	    ;;
    esac
    shift
done	    
GALAXY_DIR=$(full_path $1)
SNAPSHOT_DIR=$2
SNAPSHOT_NAME=$3
while [ $# -gt 3 ] ; do
    SNAPSHOT_NAME=${SNAPSHOT_NAME}-$4
    shift
done
SNAPSHOT_NAME=$(echo $SNAPSHOT_NAME | tr -s " " "-")
echo Galaxy dir: $GALAXY_DIR
echo Snapshot dir: $SNAPSHOT_DIR
echo Snapshot name: $SNAPSHOT_NAME
#
# Check for galaxy-dist
if [ ! -d $GALAXY_DIR/galaxy-dist ] ; then
    echo ERROR no 'galaxy-dist' dir found under $GALAXY_DIR >&2
    exit 1
fi
#
# Locate configuration file
for conf in universe_wsgi.ini config/galaxy.ini ; do
    echo -n Looking for $conf...
    config_file=$GALAXY_DIR/galaxy-dist/$conf
    if [ -f $config_file ] ; then
	echo yes
	break
    else
	echo no
	config_file=
    fi
done
if [ -z "$config_file" ] ; then
    echo ERROR no config file found >&2
    exit 1
fi
#
# Database details
echo -n "Detecting database..."
database_connection=$(grep "^database_connection" $config_file | tail -1 | cut -f2- -d"=")
if [ -z "$database_connection" ] ; then
    # Capture the default which is commented out
    database_connection=$(grep "^#database_connection" $config_file | tail -1 | cut -f2- -d"=")
fi
db_type=$(echo $database_connection | cut -d":" -f1)
if [ "$db_type" == "sqlite" ] ; then
    # Extract database file name
    echo "sqlite"
    sqlite_db=$(echo $database_connection | cut -f2- -d":" | cut -f1 -d"?" | sed 's/\/\/\///g' | sed 's/\.\///g')
elif [ "$db_type" == "postgres" ] || [ "$db_type" == "postgresql" ] ; then
    # Extract user, password and db name
    echo "postgresql"
    psql_db=$(echo $database_connection | cut -f4 -d"/")
    psql_user=$(echo $database_connection | cut -f3 -d"/" | cut -f1 -d":")
    psql_passwd=$(echo $database_connection | cut -f3 -d"/" | cut -f2 -d":" | cut -f1 -d"@")
    psql_host=$(echo $database_connection | cut -f3 -d"/" | cut -f2 -d":" | cut -f2 -d"@")
    psql_port=$(echo $database_connection | cut -f3 -d"/" | cut -f3 -d":")
else
    # Unknown/not found
    echo "unknown"
    echo "ERROR database type '$db_type' unrecognised" >&2
    exit 1
fi
echo -n "Locating 'files' part of the database..."
file_path=$(grep "^#\?file_path" $config_file | tail -1 | cut -f2- -d"=")
file_path=$(echo $file_path) # Trick to strip leading spaces
if [ ! -z "$file_path" ] ; then
    echo $file_path
    if [ ! -z "$(is_subdir $file_path $GALAXY_DIR)" ] ; then
	local_files=yes
    fi
else
    echo not found
    echo ERROR could not extract 'file_path' >&2
    exit 1
fi
echo -n "Locating 'galaxy_data_manager_data_path'..."
data_path=$(grep "^#\?galaxy_data_manager_data_path" $config_file | tail -1 | cut -f2- -d"=")
data_path=$(echo $data_path) # Trick to strip leading spaces
if [ ! -z "$data_path" ] ; then
    echo $data_path
    if [ ! -z "$(is_subdir $data_path $GALAXY_DIR)" ] ; then
	local_data=yes
    fi
else
    echo not found
    echo WARNING could not extract 'galaxy_data_manager_data_path' >&2
fi
#
# Report if some data are not under Galaxy dir
if [ -z "$local_files" ] || [ -z "$local_data" ] ; then
    if [ -z "$include_external" ] ; then
	echo WARNING database 'files' and/or data manager data are not under $GALAXY_DIR >&2
	echo Use --include-external option to also copy these files >&2
    fi
else
    local_files=yes
fi
#
# Sort out destination directory for snapshots
if [ ! -e "$SNAPSHOT_DIR" ] ; then
    echo -n Making top level snapshot directory: $SNAPSHOT_DIR...
    mkdir -p $SNAPSHOT_DIR
    echo done
fi
#
# Check that snapshots are not under galaxy dir
SNAPSHOT_DIR=$(full_path $SNAPSHOT_DIR)
if [ -z "$(echo $SNAPSHOT_DIR | grep -v $GALAXY_DIR)" ] ; then
    echo ERROR snapshot dir is subdir of galaxy dir >&2
    exit 1
fi
#
# Make timestamped snapshot subdir
timestamp=$(date +%s-%Y_%m_%d)
snapshot_dir=$SNAPSHOT_DIR/$(basename $GALAXY_DIR)/snapshot-$timestamp
if [ ! -z "$SNAPSHOT_NAME" ] ; then
    snapshot_dir=${snapshot_dir}.${SNAPSHOT_NAME}
fi
if [ -d $snapshot_dir ] ; then
    echo ERROR snapshot dir $snapshot_dir already exists >&2
    exit 1
fi
echo -n Making $snapshot_dir...
mkdir -p $snapshot_dir
echo done
#
# Copy everything
echo -n Copying...
cp -a $GALAXY_DIR/* $snapshot_dir
if [ $? -ne 0 ] ; then
    echo FAILED
    echo ERROR cp returned nonzero status >&2
    exit 1
else
    echo done
fi
#
# Dump the SQL database (if not sqlite)
if [ "$db_type" == "postgres" ] || [ "$db_type" == "postgresql" ] ; then
    # Set up destination for Postgres dump
    pg_dump_file=$snapshot_dir/${psql_db}.pg_dump.${timestamp}.sql
    # Set up and run the command to dump the SQL
    pg_dump_cmd="pg_dump -h $psql_host -p $psql_port -U $psql_user $psql_db"
    echo -n Exporting SQL database contents to $pg_dump_file...
    export PGPASSWORD=$psql_passwd
    $pg_dump_cmd > $pg_dump_file
    unset PGPASSWORD
    echo done
fi
#
# Copy files part of database (if separate)
if [ ! -z "$include_external" ] ; then
    if [ -z "$local_files" ] ; then
	files_snapshot_dir=$snapshot_dir/_files.${timestamp}
	echo -n Copying database files to $(basename $files_snapshot_dir)...
	mkdir -p $files_snapshot_dir
	if [ ! -z "$(ls $file_path)" ] ; then
	    cp -a $file_path/* $files_snapshot_dir
	    echo done
	else
	    echo done \(no files to copy\)
	fi
    fi
    if [ -z "$local_data" ] ; then
	data_snapshot_dir=$snapshot_dir/_managed_data.${timestamp}
	echo -n Copying managed data files to $(basename $data_snapshot_dir)...
	mkdir -p $data_snapshot_dir
	if [ ! -z "$(ls $data_path)" ] ; then
	    cp -a $data_path/* $data_snapshot_dir
	    echo done
	else
	    echo done \(no files to copy\)
	fi
    fi
fi
#
# Remove .pid files for servers
echo Cleaning up pid files for servers:
for server in $(grep "^\[server:" $config_file | cut -d: -f2- | cut -d"]" -f1) ; do
    if [ $server == "main" ] ; then
	server=paster
    fi
    pid_file=$snapshot_dir/galaxy-dist/$server.pid
    if [ -f $pid_file ] ; then
	echo -n "* $server: removing pid file..."
	rm -f $snapshot_dir/galaxy-dist/$server.pid
	echo done
    else
	echo "* $server: no pid file"
    fi
done
# Report the size of the snapshot
du -sh $snapshot_dir
exit 0
##
#

