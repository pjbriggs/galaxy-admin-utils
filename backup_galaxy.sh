#!/bin/sh
#
# Script to automate backup of Galaxy database
#
# Usage: backup_galaxy.sh [--dry-run] GALAXY_DIR [ BACKUP_DIR ]
#
# Reads information from universe_wsgi.ini file in GALAXY_DIR and
# generates a dump of the SQL database, plus a "mirroring" rsync
# of the database files directory.
#
# Creates the following directory structure under BACKUP_DIR:
#
#   logs/    Logs from rsyncing the files & code
#   files/   Mirror of Galaxy's database/files directory
#   sql/     Timestamped SQL dumps from Galaxy's database
#   code/    Mirror of the Galaxy code (ie galaxy-dist, local_tools
#            shed_tools and cluster_environment_setup file etc)
#
# If BACKUP_DIR is not specified then it defaults to the current
# working directory.
#
# If --dry-run is specified then the directory structure is
# created and the SQL dump and rsync commands are constructed but
# not executed.
#
# Process command line
dry_run=
if [ "$1" == "--dry-run" ] ; then
    echo "*** DRY RUN MODE ***"
    dry_run=yes
    shift
fi
if [ -z "$1" ] ; then
    echo "Usage: $0 [--dry-run] GALAXY_DIR [ BACKUP_DIR ]"
    exit
fi
GALAXY_DIR=$1
BACKUP_DIR=$2
#
# Sort out destination directory for backups
if [ -z "$BACKUP_DIR" ] ; then
    BACKUP_DIR=$(pwd)
fi
if [ ! -d $BACKUP_DIR ] ; then
    mkdir -p $BACKUP_DIR
fi
#
# Create datestamp string
datestamp=`date +%Y_%m_%d`
#
# Build backup subdirectory structure
sql_dir=$BACKUP_DIR/sql/$datestamp
if [ ! -d $sql_dir ] ; then
    mkdir -p $sql_dir
fi
if [ ! -d $BACKUP_DIR/files ] ; then
    mkdir -p $BACKUP_DIR/files
fi
log_dir=$BACKUP_DIR/logs/$datestamp
if [ ! -d $log_dir ] ; then
    mkdir -p $log_dir
fi
if [ ! -d $BACKUP_DIR/code ] ; then
    mkdir -p $BACKUP_DIR/code
fi
#
# Look for universe_wsgi.ini and extract SQL database details
#
# Formats are:
# sqlite:///./database/universe.sqlite?isolation_level=IMMEDIATE
# postgres://user:password@localhost:5432/database
universe_wsgi=$GALAXY_DIR/universe_wsgi.ini
if [ ! -f $universe_wsgi ] ; then
    echo "Can't find $universe_wsgi.ini" >&2
    exit 1
fi
database_connection=`grep "^database_connection" $universe_wsgi | tail -1 | cut -f2- -d"="`
if [ -z "$database_connection" ] ; then
    # Capture the default which is commented out
    database_connection=`grep "^#database_connection" $universe_wsgi | tail -1 | cut -f2- -d"="`
fi
# Uncomment for testing
##database_connection=" postgres://galaxy:secret@127.0.0.1:5432/galaxy_prod"
##database_connection=" sqlite:///./database/universe.sqlite?isolation_level=IMMEDIATE"
db_type=`echo $database_connection | cut -d":" -f1`
if [ "$db_type" == "postgres" ] || [ "$db_type" == "postgresql" ] ; then
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
elif [ "$db_type" == "sqlite" ] ; then    
    # Extract database file name
    echo "Sqlite database engine"
    sqlite_db=`echo $database_connection | cut -f2- -d":" | cut -f1 -d"?" | sed 's/\/\/\///g' | sed 's/\.\///g'`
    sqlite_db=$GALAXY_DIR/$sqlite_db
else
    echo "Backup for '$db_type' database not implemented"
    echo "Stopping"
    exit
fi
#
# Locate the files part of the database
file_path=`grep "^#\?file_path" $universe_wsgi | tail -1 | cut -f2- -d"="`
file_path=$(echo $file_path) # Trick to strip leading spaces
if [ -z "$file_path" ] ; then
    echo "ERROR could not extract file_path"
    echo "Stopping"
    exit 1
fi
DB_DIR=$GALAXY_DIR/$file_path
echo "Database files: $DB_DIR"
if [ ! -d $DB_DIR ] ; then
    echo "ERROR not a directory"
    echo "Stopping"
    exit 1
fi
#
# Backup the SQL database
timestamp=`date +%Y%m%d%H%M%S`
if [ "$db_type" == "postgres" ] ; then
    # Set up destination for Postgres dump
    pg_dump_file=$sql_dir/galaxy_db.${timestamp}.pg_dump
    # Set up and run the command to dump the SQL
    pg_dump_cmd="pg_dump -h $psql_host -p $psql_port -U $psql_user $psql_db"
    echo "Dumping the SQL database contents to $pg_dump_file"
    export PGPASSWORD=$psql_passwd
    echo "$pg_dump_cmd > $pg_dump_file"
    if [ -z "$dry_run" ] ; then
	$pg_dump_cmd > $pg_dump_file
    fi
elif [ "$db_type" == "sqlite" ] ; then
    # Set up destination for SQLite dump
    sqlite_dump_file=$sql_dir/galaxy_db.${timestamp}.sqlite_dump
    # Set up and run the command to dump the SQL
    sqlite_dump_cmd="echo .dump | sqlite3 $sqlite_db"
    echo "Dumping the SQL database contents to $sqlite_dump_file"
    echo "$sqlite_dump_cmd > $sqlite_dump_file"
    if [ -z "$dry_run" ] ; then
	$sqlite_dump_cmd > $sqlite_dump_file
    fi
fi
#
# Mirror the database files using rsync
db_backup_dir=$BACKUP_DIR/files
log_file=$log_dir/files.backup.${timestamp}.log
rsync_cmd="rsync"
if [ ! -z "$dry_run" ] ; then
    rsync_cmd="$rsync_cmd --dry-run"
    log_file=$log_dir/dry-run.files.backup.${timestamp}.log
fi
rsync_cmd="$rsync_cmd -av --delete-after ${DB_DIR}/ $db_backup_dir"
echo "Database files: running $rsync_cmd"
$rsync_cmd 2>&1 > $log_file
#
# Mirror the Galaxy code using rsync
code_backup_dir=$BACKUP_DIR/code
log_file=$log_dir/code.backup.${timestamp}.log
base_rsync_cmd="rsync"
if [ ! -z "$dry_run" ] ; then
    base_rsync_cmd="$base_rsync_cmd --dry-run"
    log_file=$log_dir/dry-run.code.backup.${timestamp}.log
fi
rsync_cmd="$base_rsync_cmd -av --delete-after --exclude=/database/files/* -m ${GALAXY_DIR}/ $code_backup_dir/galaxy-dist"
echo "galaxy-dist: running $rsync_cmd"
$rsync_cmd 2>&1 > $log_file
#
# Other directories
code_dirs="local_tools shed_tools tool_dependencies galaxy_env galaxy_venv cluster_environment_setup.sh"
for code_dir in $code_dirs ; do
    d=${GALAXY_DIR}/../$code_dir
    if [ -e $d ] ; then
	rsync_cmd="$base_rsync_cmd -av --delete-after -m $d $code_backup_dir"
	echo "${code_dir}: running $rsync_cmd"
	$rsync_cmd 2>&1 >> $log_file
    else
	echo "${code_dir}: not found, skipped"
    fi
done
#
# Report the sizes of SQL, files and code backups
du -sh $BACKUP_DIR
du -sh $BACKUP_DIR/sql
du -sh $BACKUP_DIR/files
du -sh $BACKUP_DIR/code
du -sh $BACKUP_DIR/logs
echo "Done"
exit
##
#
