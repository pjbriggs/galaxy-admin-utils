galaxy-admin-utils
==================

Utility scripts to help with managing local production instances of Galaxy.

Monitoring and controlling Galaxy processes in a multi-server set-up
--------------------------------------------------------------------

 * _galaxy_status.sh_: monitor status of Galaxy server processes

   Usage: `galaxy_status.sh`

   Must be run from the location were the Galaxy .pid and .log files have been
   written.

   Reports the status of each server process that has a PID file, either
   _Running_ (server is alive but not yet serving content), _Active_ (server
   is available to serve content), or _Not running_ (server is no longer
   alive).

*  _run-server.sh_: interact with a single Galaxy server process

   Usage: `run-server.sh SERVER args...`

   Must be executed from the directory where the `run.sh` and `universe_wsgi.ini`
   files are located

   Can be used to interact with a single Galaxy server process in a load-balanced 
   set-up where there are multiple co-operating servers e.g. `web0`, `web1`,
   `manager`, `handler0` etc

   For example to stop `handler1` do

      $ sh run-server.sh web0 --stop-daemon

*  _rolling-restart.sh_: restart Galaxy processes in a "rolling" fashion

   Usage: `rolling-restart.sh [OPTIONS]`

   Must be executed from the directory where the `run.sh` and `universe_wsgi.ini`
   files are located

   Stops and starts each of the servers listed in universe_wsgi.ini in turn
   waiting for each one to come back online before restarting the next.

   If specified, OPTIONS can be one or more of the arguments recognised by run.sh.

   For set ups with multiple handlers and web servers this should mean that Galaxy
   remains available to end users throughout the restart process.

   For "legacy" Galaxy setups which specify a "manager" server process, this will
   not be restarted via this script (use e.g. run-server.sh instead).

Backing up/copying Galaxy data and codebase
-------------------------------------------

 * _backup_galaxy.sh_: dump SQL database and rsync database files and
   codebase for a local Galaxy instance

   Usage: `backup_galaxy.sh [--dry-run] GALAXY_DIR [ BACKUP_DIR ]`

   Reads information from universe_wsgi.ini file in GALAXY_DIR and
   generates a dump of the SQL database, plus a "mirroring" rsync
   of the database files directory and the Galaxy codebase.

   Creates the following directory structure under BACKUP_DIR:

    logs/    Logs from rsyncing the files
    code/    Mirror of galaxy-dist, local_tools, shed_tools etc
    files/   Mirror of Galaxy's database/files directory
    sql/     Timestamped SQL dumps from Galaxy's database

   If `BACKUP_DIR` is not specified then it defaults to the current
   working directory.

   If `--dry-run` is specified then the directory structure is
   created and the SQL dump and rsync commands are constructed but
   not executed.

 * _snapshot_galaxy.sh_: make a complete copy of a local Galaxy
   install.

   Usage: `snapshot_galaxy.sh GALAXY_DIR SNAPSHOT_DIR [ NAME ]`

   Essentially does `cp -a` of the entire contents of a Galaxy install
   directory to a timestamped subdirectory under `SNAPSHOT_DIR`.
   Versions can be restored using `cp -a` from the snapshot directory.

   This script is only suitable for small local installs which
   use the SQLite database backend (i.e. those produced by the
   `install_galaxy.sh` script); for production-type instances
   use `backup_galaxy.sh`.

Quick deployment of local Galaxy instances
------------------------------------------

The old `deploy_galaxy.sh` script (which automatically created a basic local
instance of Galaxy) has been removed - the `install_galaxy.sh` script <https://github.com/pjbriggs/bioinf-software-install/blob/master/install_galaxy.sh> has replaced it.

Toolbox filters
---------------

Toolbox filter files are in the `toolbox_filters` subdirectory:

 * _metagenomics.py_

See <https://wiki.galaxyproject.org/UserDefinedToolboxFilters> for information
on installing and using toolbox filters in Galaxy.


Acknowledgements
----------------

Thanks to the following for their contributions and improvements:

 * __Brad Langhorst__ <https://github.com/bwlang>
 * __Iyad Kandalaft__ <https://github.com/IyadKandalaft>
