#!/bin/sh
#
# deploy_galaxy.sh: create a basic local instance of Galaxy
# Peter Briggs, University of Manchester 2013
#
# Usage: deploy_galaxy.sh DIR
#
# DIR = directory to put Galaxy instance into
#
# Command line
GALAXY_DIR=$1
if [ -z "$GALAXY_DIR" ] ; then
  echo "Usage: $0 DIR"
  exit
fi
# Check that the target directory doesn't already exist
if [ -e $GALAXY_DIR ] ; then
  echo "$GALAXY_DIR: already exists"
  exit 1
fi
# Start
echo "Making directory $GALAXY_DIR"
mkdir $GALAXY_DIR
cd $GALAXY_DIR
# Make a Python virtualenv for this instance
echo "Making virtualenv..."
virtualenv galaxy_venv >> install.log
echo "Activating virtualenv"
. galaxy_venv/bin/activate
# Install dependencies
echo "Installing NumPy..."
pip install numpy >> install.log
echo "Downloading and installing patched RPy..."
wget -O rpy-1.0.3-patched.tar.gz https://dl.dropbox.com/s/r0lknbav2j8tmkw/rpy-1.0.3-patched.tar.gz?dl=1 2>&1 >> install.log
pip install -f file://${PWD}/rpy-1.0.3-patched.tar.gz rpy >> install.log
# Install Galaxy
echo "Cloning galaxy source code..."
hg clone https://bitbucket.org/galaxy/galaxy-dist/ 2>&1 >> install.log
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
echo "Creating area for tool shed tools"
mkdir shed_tools
echo "Making custom universe_wsgi.ini"
sed 's/#tool_config_file = .*/tool_config_file = tool_conf.xml,shed_tool_conf.xml,local_tool_conf.xml/' galaxy-dist/universe_wsgi.ini.sample > galaxy-dist/universe_wsgi.ini
# Create wrapper script to run galaxy
echo "Making wrapper script 'start_galaxy.sh'"
cat > start_galaxy.sh <<EOF
#!/bin/sh
# Automatically generated script to run galaxy
# in $GALAXY_DIR
echo "Starting Galaxy in $GALAXY_DIR"
# Activate virtualenv
. $GALAXY_DIR/galaxy_venv/bin/activate
# Start Galaxy with --reload option
cd $GALAXY_DIR/galaxy-dist
sh run.sh --reload
EOF
chmod +x start_galaxy.sh
# Finished
deactivate
echo "Finished installing Galaxy in $GALAXY_DIR"
##
#
