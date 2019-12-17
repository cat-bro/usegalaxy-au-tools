echo running tool installation script
echo --------------------------

export AU_TOOLS_DIR=usegalaxy-au-tools
#export AU_TOOLS_GIT=git@github.com:cat-bro/$AU_TOOLS_DIR.git

export GALAXY_URL=https://cat-dev.genome.edu.au

export TOOL_FILE_PATH=$AU_TOOLS_DIR/galaxy-aust-dev/graphdisplay_data.yml

echo Using variables
echo AU_TOOLS_DIR = $AU_TOOLS_DIR
#echo AU_TOOLS_GIT = $AU_TOOLS_GIT
echo GALAXY_URL = $GALAXY_URL
echo GALAXY_API_KEY = $GALAXY_API_KEY
echo TOOL_FILE_PATH = $TOOL_FILE_PATH
echo -------------------------------

export VIRTUALENV='../.venv'
if [ ! -d $VIRTUALENV ]; then
        virtualenv $VIRTUALENV;
fi
. $VIRTUALENV/bin/activate
cd .. # this is a temporary hack
pip install ephemeris
cd workspace
get-tool-list -g $GALAXY_URL -a $GALAXY_API_KEY -o installed_tools.yml
python scripts/install_added_tools.py
#shed-tools install -g $GALAXY_URL -a $GALAXY_API_KEY -t $TOOL_FILE_PATH -v
#rm -rf $AU_TOOL_DIR
