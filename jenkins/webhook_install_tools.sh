#! /bin/bash

echo running tool installation script
echo --------------------------

# AU_TOOLS_DIR=usegalaxy-au-tools
#export AU_TOOLS_GIT=git@github.com:cat-bro/$AU_TOOLS_DIR.git

STAGING_URL=https://galaxy-cat.genome.edu.au ##
PRODUCTION_URL=https://cat-dev.genome.edu.au
STAGING_TOOL_DIR=galaxy-cat
PRODUCTION_TOOL_DIR=cat-dev
AUTOMATED_TOOL_INSTALLATION_LOG='automated_tool_installation_log.tsv'; # version controlled
# TOOL_FILE_PATH=$AU_TOOLS_DIR/galaxy-aust-dev/graphdisplay_data.yml

echo Using variables
# echo AU_TOOLS_DIR = $AU_TOOLS_DIR
#echo AU_TOOLS_GIT = $AU_TOOLS_GIT
echo STAGING_URL = $STAGING_URL
echo PRODUCTION_URL = $PRODUCTION_URL
echo STAGING_TOOL_DIR = $STAGING_TOOL_DIR
echo PRODUCTION_TOOL_DIR = $PRODUCTION_TOOL_DIR

# Jenkins build number
echo BUILD_NUMBER = $BUILD_NUMBER
echo INSTALL_ID = $INSTALL_ID
echo GIT_COMMIT = $GIT_COMMIT
echo GIT_PREVIOUS_COMMIT = $GIT_PREVIOUS_COMMIT
echo -------------------------------

# Virtual environment in build directory has ephemeris and bioblend installed.
# If this script is being run for the first time we will need to set up the
# virtual environment
if [ $LOCAL_ENV = 0 ]; then
	VIRTUALENV="../.venv"
	if [ ! -d $VIRTUALENV ]; then
		echo "creating virtual environment ----------------------------------------------"
	        virtualenv $VIRTUALENV;
		cd .. # this is a temporary hack
		pip install ephemeris
		pip install bioblend
		cd workspace
	fi
	. $VIRTUALENV/bin/activate
fi

FILE_ARGS=$REQUESTS_DIFF
if [ ! -f $REQUESTS_DIFF ]; then
	FILE_ARGS=$(tr "\n" " " < $REQUESTS_DIFF)
fi

if [ ! -d tmp ]; then
	mkdir tmp;
fi

# TODO all calls to shed-tools need to catch errors

test_tool() {
	SERVER="$1"
	if [ $SERVER = "STAGING" ]; then
		API_KEY=$STAGING_API_KEY
		URL=$STAGING_URL
		TEST_LOG=$STAGING_TEST_LOG
		TEST_JSON=$STAGING_TEST_JSON
		STEP="Staging Testing"
	elif [ $SERVER = "PRODUCTION" ]; then
		API_KEY=$PRODUCTION_API_KEY
		URL=$PRODUCTION_URL
		TEST_LOG=$PRODUCTION_TEST_LOG
		TEST_JSON=$PRODUCTION_TEST_JSON
		STEP="Production Testing"
	else
		echo "First positional argument must be STAGING or PRODUCTION.  Exiting"
		continue
	fi

	# TODO it is right to specify revision when running tests?
	shed-tools test -g $URL -a $API_KEY --name $TOOL_NAME --owner $TOOL_OWNER --revisions $INSTALLED_REVISION --test_json $TEST_JSON -v &> $TEST_LOG
	cat $TEST_LOG
	TESTS_PASSED="$(python scripts/first_match_regex.py -p 'Passed tool tests \((\d+)\)' $TEST_LOG)"
	TESTS_FAILED="$(python scripts/first_match_regex.py -p 'Failed tool tests \((\d+)\)' $TEST_LOG)"
	if [ $TESTS_FAILED = 0 ]; then
		if [ $TESTS_PASSED = 0 ]; then
			echo "WARNING: There are no tests for $TOOL_NAME at revision $INSTALLED_REVISION.  Proceeding as none have failed.";
		else
			echo "All tests have passed for $TOOL_NAME at revision $INSTALLED_REVISION on $URL.";
		fi
	else
		echo "Failed to install: Winding back installation as some tests have failed.";
		echo "Uninstalling on $URL";
		python scripts/uninstall_tools.py -g $URL -a $API_KEY -n $INSTALLED_NAME;
		if [ $SERVER = "PRODUCTION" ]; then
			# also uninstall on staging
			echo "Uninstalling on $STAGING_URL";
			python scripts/uninstall_tools.py -g $STAGING_URL -a $STAGING_API_KEY -n $INSTALLED_NAME;
		fi
		echo -e "$BUILD_NUMBER\t$INSTALL_ID\t$LOG_FILE\tTests failed\tStaging tests\t$INSTALLED_NAME" >> $AUTOMATED_TOOL_INSTALLATION_LOG;
		git commit $AUTOMATED_TOOL_INSTALLATION_LOG -m "$AUTOMATED_TOOL_INSTALLATION_LOG entry for build $BUILD_NUMBER."; git push
		continue
	fi
}

install_tool() {
	# Positional arguments: $1 = STAGING|PRODUCTION, $2 = tool file path, $3 = repeat (default 1)
	if [ "$2" ]; then
		REPEAT=2;
	else
		REPEAT=1
	fi

	TOOL_FILE="$2"
	# TODO: Log file names should be distinct for different repeats
	SERVER="$1"
	if [ $SERVER = "STAGING" ]; then
		API_KEY=$STAGING_API_KEY
		URL=$STAGING_URL
		INSTALL_LOG=$STAGING_INSTALL_LOG
		STEP="Staging Installation"
	elif [ $SERVER = "PRODUCTION" ]; then
		API_KEY=$PRODUCTION_API_KEY
		URL=$PRODUCTION_URL
		INSTALL_LOG=$PRODUCTION_INSTALL_LOG
		STEP="Production Installation"
	else
		echo "First positional argument must be STAGING or PRODUCTION.  Exiting"
		continue
	fi

	# Make sure that shed-tools outcome variables are not set.
	# These may have been set in a previous iteration
	unset INSTALLATION_STATUS
	unset INSTALLED_NAME
	unset INSTALLED_REVISION
	unset BASH_REMATCH

	# Ephemeris install script
	if [ -f $INSTALL_LOG ]; then
		rm $INSTALL_LOG;
	fi
	command="shed-tools install -g $URL -a $API_KEY -t $TOOL_FILE -v --log_file $INSTALL_LOG"
	echo $command
	$command
	# cat $INSTALL_LOG

	# Capture the status (Installed/Skipped/Errored), name and revision hash
	# from ephemeris output
	if [ $LOCAL_ENV = 0 ]; then
		PATTERN="(\w+) repositories \(1\): \[\('([^']+)',\s*u?'(\w+)'\)\]"
		[[ $(cat $INSTALL_LOG) =~ $PATTERN ]];
		export INSTALLATION_STATUS="${BASH_REMATCH[1]}";
		export INSTALLED_NAME="${BASH_REMATCH[2]}";
		export INSTALLED_REVISION="${BASH_REMATCH[3]}";
	else # the regex above does not work on my local machine (Mac), hence this python workaround
		SHED_TOOLS_VALUES=($(python scripts/first_match_regex.py -p "(\w+) repositories \(1\): \[\('([^']+)',\s*u?'(\w+)'\)\]" $INSTALL_LOG));
	fi
	if [ $SHED_TOOLS_VALUES ]; then
		export INSTALLATION_STATUS="${SHED_TOOLS_VALUES[0]}";
		export INSTALLED_NAME="${SHED_TOOLS_VALUES[1]}";
		export INSTALLED_REVISION="${SHED_TOOLS_VALUES[2]}";
	fi
	# If all three values are not null, proceed only if status is Installed,
	# write log entry and leave otherwise
	if [ "$INSTALLATION_STATUS" ] && [ "$INSTALLED_NAME" ] && [ "$INSTALLED_REVISION" ]; then
		if [ ! $INSTALLATION_STATUS = 'Installed' ]; then
			if [ $INSTALLATION_STATUS = "Errored" ]; then
				# The tool may or may not be installed according to the API, so it needs to be
				# uninstalled with bioblend
				echo "Installation error.  Uninstalling $TOOL_NAME on $URL";
				# TODO improve uninstall script so it can take --name --owner --revision
				python scripts/uninstall_tools.py -g $URL -a $API_KEY -n $INSTALLED_NAME;
				if [ $SERVER = "PRODUCTION" ]; then
					# also uninstall on staging
					echo "Uninstalling $TOOL_NAME on $STAGING_URL";
					python scripts/uninstall_tools.py -g $STAGING_URL -a $STAGING_API_KEY -n $INSTALLED_NAME;
				fi
				echo "Halting unsuccessful installation";
			elif [ $INSTALLATION_STATUS = "Skipped" ]; then
				# Note that linting process should prevent this scenario
				echo "Package appears to be already installed on $URL";
			fi
			# TODO: What are relevant log values?  Owner.  Revision.  Section.  Toolshed URL. Start time.  Finish time.  Elapsed time.
			echo -e "$BUILD_NUMBER\t$INSTALL_ID\t$LOG_FILE\t$INSTALLATION_STATUS\t$STEP\t$INSTALLED_NAME" >> $AUTOMATED_TOOL_INSTALLATION_LOG;
			git commit $AUTOMATED_TOOL_INSTALLATION_LOG -m "$AUTOMATED_TOOL_INSTALLATION_LOG entry for build $BUILD_NUMBER."; git push
			# TODO: Should files be moved elsewhere?
			continue;
		else
			if [! $TOOL_NAME = $INSTALLED_NAME ]; then
				# Sanity check.  If these are not the same name, uninstall and abandon process with 'Script error'
				python scripts/uninstall_tools.py -g $URL -a $API_KEY -n $INSTALLED_NAME;
				echo -e "$BUILD_NUMBER\t$INSTALL_ID\t$LOG_FILE\tScript Error\tStaging installation\t$INSTALLED_NAME" >> $AUTOMATED_TOOL_INSTALLATION_LOG;
				git commit $AUTOMATED_TOOL_INSTALLATION_LOG -m "$AUTOMATED_TOOL_INSTALLATION_LOG entry for build $BUILD_NUMBER."; git push
				continue;
			fi
			echo "Successfully installed $TOOL_NAME on $URL";
		fi
		else
			echo "Could not verify installation from shed-tools output";
			continue;
	fi
}

extract_tool_data() {
	export TOOL_NAME=$(echo $(grep -oE "name: (\w+)" "$1") | awk '{print $2}')
	export TOOL_OWNER=$(echo $(grep -oE "owner: (\w+)" "$1") | awk '{print $2}')
}

prepare_tool_files() {
	# split requests into individual yaml files in requests/pending
	# one file per unique revision so that installation can be run sequentially and
	# failure of one installation will not affect the others
	# Use python for this.
	export TOOL_FILE_PATH="requests/pending/$INSTALL_ID/"
	mkdir -p $TOOL_FILE_PATH
	python scripts/organise_request_files.py -f $FILE_ARGS -o $TOOL_FILE_PATH  # TODO catch problems?
}

# TOOL_FILE_PATH="requests/pending/$INSTALL_ID/"
prepare_tool_files
TMP=tmp/$INSTALL_ID/
mkdir $TMP
for FILE_NAME in $(ls $TOOL_FILE_PATH)

do
	TOOL_FILE=$TOOL_FILE_PATH$FILE_NAME
	TOOL_REF=$(echo $FILE_NAME | cut -d'.' -f 1)
	export STAGING_INSTALL_LOG="$TMP"staging_"$TOOL_REF"_install_log.txt
	export STAGING_TEST_LOG="$TMP"staging_"$TOOL_REF"_test_log.txt
	export STAGING_TEST_JSON="$TMP"staging_"$TOOL_REF"_test.json
	export PRODUCTION_INSTALL_LOG="$TMP"production_"$TOOL_REF"_install_log.txt
	# TODO second production install log, move these to individual test/install routines
	export PRODUCTION_TEST_LOG="$TMP"production_"$TOOL_REF"_test_log.txt
	export PRODUCTION_TEST_JSON="$TMP"production_"$TOOL_REF"_test.json

	extract_tool_data $TOOL_FILE

		echo -e "\nStep (1): Installing $TOOL_NAME on staging server";
		#install_on_staging_server $FILE_ARGS && echo 'Installation script exited with 0 (success)'
		install_tool "STAGING" $TOOL_FILE

		echo -e "\nStep (2): Testing $TOOL_NAME on staging server";
		test_tool "STAGING"

		echo -e "\nStep (3): Installing $TOOL_NAME on production server";
		install_tool "PRODUCTION" $TOOL_FILE

		echo -r "\nStep (4): Testing $TOOL_NAME on production server";
		test_tool "PRODUCTION"

	echo -e '\n\n'
	# SUCCESS

	# python scripts/split_tool_yml.py
done

echo 'Now we need some stats about successful/unsuccessful installations.  End of script.'
