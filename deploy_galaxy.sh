#!/bin/sh
#
# deploy_galaxy.sh: create a basic local instance of Galaxy
# Peter Briggs, University of Manchester 2013
#
# Usage: deploy_galaxy.sh [ OPTIONS ] DIR
#
# DIR = directory to put Galaxy instance into
#
# Available options:
# --port PORT: use PORT rather than default (8080)
# --admin_users EMAIL[,EMAIL...]: set admin user email addresses
#
# Command line
port=
admin_users=
while [ $# -gt 1 ] ; do
    if [ "$1" == "--port" ] ; then
        # User specified port number
	shift
	if [ ! -z "$1" ] ; then
	    port=$1
	fi
    elif [ "$1" == "--admin_users" ] ; then
	shift
	if [ ! -z "$1" ] ; then
	    admin_users=$1
	fi
    fi
    # Next argument
    shift
done
# Get Galaxy directory
if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
  echo "Usage: $0 [ OPTIONS ] DIR"
  echo ""
  echo "Create a new Galaxy instance under directory DIR"
  echo ""
  echo "Options:"
  echo "  --port PORT: use PORT rather than 8080"
  echo "  --admin_users: EMAIL[,EMAIL...]: set admin user emails"
  exit
fi
GALAXY_DIR=$1
# Check that the target directory doesn't already exist
if [ -e $GALAXY_DIR ] ; then
  echo "$GALAXY_DIR: already exists"
  exit 1
fi
# Start
echo "Making subdirectory $GALAXY_DIR in $(pwd)"
mkdir $GALAXY_DIR
if [ ! -d "$GALAXY_DIR" ] ; then
    echo "Failed to make directory $GALAXY_DIR"
    exit 1
fi
cd $GALAXY_DIR
GALAXY_DIR=$(pwd)
# Make a Python virtualenv for this instance
got_virtualenv=`/usr/bin/which virtualenv 2>&1 | grep -v "^/usr/bin/which: no virtualenv in"`
if [ -z "$got_virtualenv" ] ; then
    echo "ERROR: Python 'virtualenv' not found on your PATH"
    exit 1
fi
echo -n "Making virtualenv..."
virtualenv galaxy_venv >> install.log
echo "ok"
echo -n "Activating virtualenv..."
. galaxy_venv/bin/activate
echo "ok"
# Install dependencies
echo -n "Installing NumPy..."
pip install numpy >> install.log
echo "ok"
echo -n "Downloading and installing patched RPy..."
wget -O rpy-1.0.3-patched.tar.gz https://dl.dropbox.com/s/r0lknbav2j8tmkw/rpy-1.0.3-patched.tar.gz?dl=1 &>> install.log
pip install -f file://${PWD}/rpy-1.0.3-patched.tar.gz rpy >> install.log
echo "ok"
# Install Galaxy
echo -n "Cloning galaxy source code..."
hg clone https://bitbucket.org/galaxy/galaxy-dist/ &>> install.log
echo "ok"
# Create somewhere for local tools
echo "Creating area for local tools"
mkdir local_tools
echo "Creating local_tool_conf.xml file"
cat > galaxy-dist/local_tool_conf.xml <<EOF
<?xml version="1.0"?>
<toolbox tool_path="../local_tools">
<label id="local_tools" text="Local Tools" />
  <!-- Example of section and tool definitions -->
  <section id="example_tools" name="Local Tools">
  	<!--Add tool references here-->
  </section>
</toolbox>
EOF
# Set up directories for shed tools and managed tools
echo "Creating area for tool shed tools"
mkdir shed_tools
echo "Creating area for managed packages"
mkdir managed_packages
echo "Making custom universe_wsgi.ini"
sed 's/#tool_config_file = .*/tool_config_file = tool_conf.xml,shed_tool_conf.xml,local_tool_conf.xml/' galaxy-dist/universe_wsgi.ini.sample > galaxy-dist/universe_wsgi.ini
sed -i 's,#tool_dependency_dir = None,tool_dependency_dir = ../managed_packages,' galaxy-dist/universe_wsgi.ini
# Set the brand
brand=$(basename $GALAXY_DIR)
echo "Setting brand to $brand"
sed -i 's,#brand = None,brand = '"$brand"',' galaxy-dist/universe_wsgi.ini
# Set non-default port
if [ ! -z "$port" ] ; then
    echo "Setting port to $port"
    sed -i 's,#port = 8080,port = '"$port"',' galaxy-dist/universe_wsgi.ini
fi
# Set admin users
if [ ! -z "$admin_users" ] ; then
    echo "Adding $admin_users to admin user emails"
    echo "(You still need to create these accounts once Galaxy has started)"
    sed -i 's,#admin_users = None,admin_users = '"$admin_users"',' galaxy-dist/universe_wsgi.ini
fi
# Create wrapper script to run galaxy
echo "Making generic wrapper script 'start_galaxy.sh'"
cat > start_galaxy.sh <<EOF
#!/bin/sh
# Automatically generated script to run galaxy
# in $(basename $GALAXY_DIR)
GALAXY_DIR=\$(dirname \$0)
if [ -z \$(echo \$GALAXY_DIR | grep "^/") ] ; then
  GALAXY_DIR=\$(pwd)/\$GALAXY_DIR
fi
echo "Starting Galaxy in \$GALAXY_DIR"
# Activate virtualenv
. \$GALAXY_DIR/galaxy_venv/bin/activate
# Start Galaxy with --reload option
cd \$GALAXY_DIR/galaxy-dist
sh run.sh --reload 2>&1 | tee \$GALAXY_DIR/galaxy.log
EOF
chmod +x start_galaxy.sh
# Finished
deactivate
echo "Finished installing Galaxy in $GALAXY_DIR"
##
#
