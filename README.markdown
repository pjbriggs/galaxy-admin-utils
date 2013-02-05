galaxy-admin-utils
==================

Utility scripts to help with managing local production instances of Galaxy.

Quick deployment of local Galaxy instances
------------------------------------------

 * _deploy_galaxy.sh_: automatically create a basic local instance of Galaxy

   Usage: `deploy_galaxy.sh DIR`

   Creates a new directory `DIR` and then sets up a Python virtualenv, clones
   and configures a copy of `galaxy-dist`, sets up a subdirectory `local_tools`
   pointed to by `local_tool_conf.xml`, and creates a `start_galaxy.sh` script
   to launch the new local instance.

 * _add_tool.sh_: automatically add tool files into local instance from `deploy_galaxy.sh`

   Usage: `add_tool.sh DIR TOOL.xml TOOL_WRAPPER`

   Simple script to add a Galaxy tool to a local instance previously created by
   `deploy_galaxy.sh`.


Backing up/copying Galaxy data and codebase
-------------------------------------------

 * _backup_database.sh_: dump SQL database and rsync data files for a local
   Galaxy instance

   Usage: `backup_database.sh [--dry-run] GALAXY_DIR`

   Dumps the SQL contents of the Galaxy distribution in `GALAXY_DIR` into the
   current working directory, and also makes (or updates) an rsync copy of the
   database/files directory.

 * _backup_galaxy.sh_: rsync a subset of the code base for a local Galaxy
   instance

