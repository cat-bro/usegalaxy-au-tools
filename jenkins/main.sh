#echo "Something has changed on github"
#echo $PRODUCTION_API_KEY
#cd galaxy_tool_automation
chmod +x jenkins/webhook_install_tools.sh
# chmod +x jenkins/check_changed_files.sh

export LOG_DIR=~/galaxy_tool_automation
if [ ! -d LOG_DIR ]; then
	mkdir LOG_DIR
fi
LOG_FILE=$LOG_DIR/webhook_tool_installation_$(date '+%Y%m%d%H%M%S')

echo 'GIT DIFF'
git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only

# First check whether changed files are in the path of tool requests.
# If so, we run the install script.  If not, exit 1.
# export CHANGED_FILES=$(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only | cat)
export REQUESTS_DIFF=$(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only --diff_filter=a | cat | grep "^requests\/[^\/]*$")

#echo 'Changes have been made to the following files:'
#echo $CHANGED_FILES

if [ ! $REQUESTS_DIFF ]; then
	echo 'No added files in requests folder, no tool installation required';
	exit 0;
else
	echo 'Tools from the following files will be installed';
	echo $REQUESTS_DIFF;
fi

echo 'Saving output to $LOG_FILE'
bash jenkins/webhook_install_tools.sh &> $LOG_FILE

cat $LOG_FILE
