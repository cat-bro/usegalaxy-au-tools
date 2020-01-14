#! /bin/bash

echo running tool installation script
echo --------------------------

AU_TOOLS_DIR=usegalaxy-au-tools
#export AU_TOOLS_GIT=git@github.com:cat-bro/$AU_TOOLS_DIR.git

STAGING_URL=https://galaxy-cat.genome.edu.au ##
PRODUCTION_URL=https://cat-dev.genome.edu.au
STAGING_TOOL_DIR=galaxy-cat
PRODUCTION_TOOL_DIR=cat-dev
TOOL_FILE_PATH=$AU_TOOLS_DIR/galaxy-aust-dev/graphdisplay_data.yml

echo Using variables
echo AU_TOOLS_DIR = $AU_TOOLS_DIR
#echo AU_TOOLS_GIT = $AU_TOOLS_GIT
echo STAGING_URL = $STAGING_URL
echo PRODUCTION_URL = $PRODUCTION_URL
# echo STAGING_API_KEY = $STAGING_API_KEY
# echo PRODUCTION_API_KEY = $PRODUCTION_API_KEY
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
if [ $LOCAL_ENV = 0 ]; then
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
fi
# get-tool-list -g $STAGING_URL -a $GALAXY_API_KEY -o installed_tools.yml
chmod +x scripts/install_added_tools.py
echo $REQUESTS_DIFF
echo $(tr '\n' ' ' < $REQUESTS_DIFF)
FILE_ARGS=$REQUESTS_DIFF
if [ ! -f $REQUESTS_DIFF ]; then
	FILE_ARGS=$(tr '\n' ' ' < $REQUESTS_DIFF)
fi


# split requests into individual yaml files in requests/pending
# either that or amalgamate them into one file to run through shed-tools
# python split_requests.py

# INSTALL_STAGING_RESULT=$(python scripts/install_added_tools.py -g $STAGING_URL -a $STAGING_API_KEY -f $(tr '\n' ' ' < $REQUESTS_DIFF))
# python scripts/install_added_tools.py -g $STAGING_URL -a $STAGING_API_KEY -f $FILE_ARGS

if [ ! -d tmp ]; then
	mkdir tmp;
fi

STAGING_INSTALL_LOG=tmp/staging_install_$INSTALL_ID.log
STAGING_TEST_LOG=tmp/staging_test_$INSTALL_ID.log
STAGING_TEST_JSON=tmp/staging_test_$INSTALL_ID.json

# (1) Install tool on staging server
install_on_staging_server() {
	shed-tools install -g $STAGING_URL -a $STAGING_API_KEY -t "$1" -v &> $STAGING_INSTALL_LOG
	cat $STAGING_INSTALL_LOG
	if [ $LOCAL_ENV = 0 ]; then
		$PATTERN="(\w+) repositories \(1\): \[\('([^']+)',\s*u'(\w+)'\)\]"
		[[ $(cat $STAGING_INSTALL_LOG) =~ $PATTERN ]];
		export INSTALLATION_STATUS="${BASH_REMATCH[1]}";
		export INSTALLED_NAME="${BASH_REMATCH[2]}";
		export INSTALLED_REVISION="${BASH_REMATCH[3]}";
		# TODO: Check that values exist and status is installed
	else # the regex above does not work on my local machine, hence this workaround
		SHED_TOOLS_VALUES=$(python scripts/verify_shed_tools_installation.py $STAGING_INSTALL_LOG);
		echo 'shed tools values'
		echo $SHED_TOOLS_VALUES
		if [ $SHED_TOOLS_VALUES ]; then
			export INSTALLATION_STATUS="$SHED_TOOLS_VALUES[1]";
			export INSTALLED_NAME="$SHED_TOOLS_VALUES[2]";
			export INSTALLED_REVISION="$SHED_TOOLS_VALUES[3]";
		fi
	fi
	echo $INSTALLATION_STATUS
	echo $INSTALLED_NAME
	echo $INSTALLED_REVISION
	if [ $INSTALLATION_STATUS ] && [ $INSTALLED_NAME ] && [ $INSTALLED_REVISION ]; then
		# check that status is 'installed'
		echo 'In first loop ----------------------'
		if [ ! $INSTALLATION_STATUS = 'Installed' ]; then
			# TODO check whether 'error' or 'skipped', take action
			# move file, commit
			# log
			echo "Installation unsuccessful (status $INSTALLATION_STATUS).  Halting.";
			exit 1; # Nothing else to do here
		else
			exit 0;
		fi
	fi
}


# command = (
# 		'shed-tools install -g %s -a %s -t %s -v &> %s' %
# 		(galaxy_server, api_key, galaxy_tools_install_file, shed_tools_log)
# )
# sys.stderr.write(command + '\n')
# os.system(command)
# with open(shed_tools_log) as log_file:
# 		sys.stderr.write(log_file.read())
# result = verify_shed_tools_installation(shed_tools_log)
# sys.stderr.write(str(result) + '\n')
# if not (result and result['status'] == 'installed'):
# 		raise Exception('Installation status is %s.  Halting.' % result['status'])
# 		# (error): roll back installation, move file, log entry
# else:
# 		sys.stderr.write('Successfully installed %s at revision %s\n' % (result['name'], result['revision']))
#
# #if [ $INSTALL_STAGING_RESULT = 'OK' ]; then
#shed-tools install -g $GALAXY_URL -a $GALAXY_API_KEY -t $TOOL_FILE_PATH -v
#rm -rf $AU_TOOL_DIR

{
	install_on_staging_server $FILE_ARGS && echo 'Installation script exited with 0 (success)'
	# TODO: file_args should be allowed to be more than one string
} || {
	echo 'Install script exited with 1 (fail)'
}
# test_on_staging_server $FILE_ARGS
# install_on_production_server $FILE_ARGS
# test_on_production_server $FILE_ARGS
