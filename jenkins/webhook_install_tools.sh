echo running tool installation script
echo --------------------------

AU_TOOLS_DIR=usegalaxy-au-tools
#export AU_TOOLS_GIT=git@github.com:cat-bro/$AU_TOOLS_DIR.git

STAGING_URL=https://galaxy-cat.genome.edu.au ##
PRODUCTION_URL=https://cat-dev.genome.edu.au
LOCAL_TOOL_DIR=cat-dev
TOOL_FILE_PATH=$AU_TOOLS_DIR/galaxy-aust-dev/graphdisplay_data.yml

echo Using variables
echo AU_TOOLS_DIR = $AU_TOOLS_DIR
#echo AU_TOOLS_GIT = $AU_TOOLS_GIT
echo STAGING_URL = $STAGING_URL
echo PRODUCTION_URL = $PRODUCTION_URL
echo STAGING_API_KEY = $STAGING_API_KEY
echo PRODUCTION_API_KEY = $PRODUCTION_API_KEY
echo TOOL_FILE_PATH = $TOOL_FILE_PATH
echo -------------------------------

echo $REQUESTS_DIFF

# $REQUESTS_DIFF=$(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only requests/ | cat | grep "^requests\/[^\/]*$")
#
# if [ ! $REQUESTS_DIFF ]; then
# 	echo 'No difference in files in watched path, no tool installation required';
# 	exit 1;
# else
# 	echo 'Tools from the following files will be installed';
# 	echo $REQUESTS_DIFF;
# fi

# Virtual environment in build directory has ephemeris and bioblend installed.
# If this script is being run for the first time we will need to set up the
# virtual environment
VIRTUALENV='../.venv'
if [ ! -d $VIRTUALENV ]; then
	echo 'creating virtual environment ----------------------------------------------'
        virtualenv $VIRTUALENV;
	cd .. # this is a temporary hack
	pip install ephemeris
	pip install bioblend
	cd workspace
fi
. $VIRTUALENV/bin/activate
# get-tool-list -g $STAGING_URL -a $GALAXY_API_KEY -o installed_tools.yml
chmod +x scripts/install_added_tools.py
INSTALL_STAGING_RESULT=(python scripts/install_added_tools.py -g $STAGING_URL -a $STAGING_API_KEY -d $LOCAL_TOOL_DIR -f $(tr '\n' ' ' < $REQUESTS_DIFF))

if [ $INSTALL_STAGING_RESULT = 'OK' ]; then
#shed-tools install -g $GALAXY_URL -a $GALAXY_API_KEY -t $TOOL_FILE_PATH -v
#rm -rf $AU_TOOL_DIR
