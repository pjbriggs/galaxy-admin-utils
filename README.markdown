galaxy-admin-utils
==================

Utility scripts to help with managing local production instances of Galaxy.

Quick deployment of local Galaxy instances
------------------------------------------

 * _deploy_galaxy.sh_: automatically create a basic local instance of Galaxy

   Usage: `deploy_galaxy.sh [ OPTIONS ] DIR`

   Creates a new directory `DIR` and then sets up a Python virtualenv, clones
   and configures a copy of `galaxy-dist`, sets up a subdirectory `local_tools`
   pointed to by `local_tool_conf.xml`, and creates a `start_galaxy.sh` script
   to launch the new local instance.

   Options:

   --port PORT: use PORT rather than default (8080)
   --admin_users EMAIL[,EMAIL...]: set admin user email addresses

 * _add_tool.sh_: automatically add tool files into local instance from `deploy_galaxy.sh`

   Usage: `add_tool.sh DIR TOOL.xml [ TOOL_WRAPPER ]`

   Simple script to add a Galaxy tool to a local instance previously created by
   `deploy_galaxy.sh`. Copies TOOL.xml and optional TOOL_WRAPPER file to subdirectory
   DIR/local_tools/TOOL/ and adds a reference in the `local_tools_conf.xml` file.
   The tool should then be accessible on restarting the local instance.


Backing up/copying Galaxy data and codebase
-------------------------------------------

 * _backup_database.sh_: dump SQL database and rsync data files for a local
   Galaxy instance

   Usage: `backup_database.sh [--dry-run] GALAXY_DIR [ BACKUP_DIR ]`

   Reads information from universe_wsgi.ini file in GALAXY_DIR and
   generates a dump of the SQL database, plus a "mirroring" rsync
   of the database files directory.

   Creates the following directory structure under BACKUP_DIR:

    logs/    Logs from rsyncing the files
    files/   Mirror of Galaxy's database/files directory
    sql/     Timestamped SQL dumps from Galaxy's database

   If `BACKUP_DIR` is not specified then it defaults to the current
   working directory.

   If `--dry-run` is specified then the directory structure is
   created and the SQL dump and rsync commands are constructed but
   not executed.

 * _backup_galaxy.sh_: rsync a subset of the code base for a local Galaxy
   instance

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
