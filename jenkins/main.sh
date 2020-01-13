chmod +x jenkins/webhook_install_tools.sh

install_tools() {
	export LOG_DIR=~/galaxy_tool_automation
	if [ ! -d LOG_DIR ]; then
		mkdir LOG_DIR
	fi
	LOG_FILE=$LOG_DIR/webhook_tool_installation_$(date '+%Y%m%d%H%M%S')

	# echo 'GIT DIFF'
	# git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only

	# First check whether changed files are in the path of tool requests.
	# If so, we run the install script.  If not, exit 1.
	# export CHANGED_FILES=$(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only | cat)
	export REQUESTS_DIFF=$(git diff --name-only --diff-filter=A $GIT_PREVIOUS_COMMIT $GIT_COMMIT | cat | grep "^requests\/[^\/]*$")

	#echo 'Changes have been made to the following files:'
	#echo $CHANGED_FILES

	if [ ! $REQUESTS_DIFF ]; then
		echo 'No added files in requests folder, no tool installation required';
		exit 0;
	else
		echo 'Tools from the following files will be installed';
		echo $REQUESTS_DIFF;
	fi

	echo Saving output to $LOG_FILE
	if [ $LOCAL_ENV = 0 ]; then
		bash jenkins/webhook_install_tools.sh &> $LOG_FILE
		cat $LOG_FILE
	else
		bash jenkins/webhook_install_tools.sh
	fi
}

# Switch to allow the script to be run locally or remotely at stages of development
# if RUN_LOCALLY is true, the script will only run where an .env file is present
RUN_LOCALLY=1 # (1) Disable script on jenkins (0) run script on jenkins
export LOCAL_ENV=0
RUN=1 # true=1, false=0
FILE=.env
if [ -f "$FILE" ]; then
		export LOCAL_ENV=1
    echo 'Script running in local enviroment';
else
		echo 'Script running on jenkins server';
		if [ $RUN_LOCALLY = 1 ]; then
				echo 'Skipping as RUN_LOCALLY is set to 1 (true)';
				RUN=0;
		fi
fi

LOG_DIR=~/galaxy_tool_automation
if [ $LOCAL_ENV = 1 ]; then
	LOG_DIR=logs
	export $(cat .env)
	GIT_PREVIOUS_COMMIT=HEAD~1
	GIT_COMMIT=HEAD
fi

if [ $RUN = 1 ]; then
	install_tools
fi
