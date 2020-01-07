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

GIT_PREVIOUS_COMMIT=$(HEAD~1)
GIT_COMMIT=$(HEAD~0)

# echo 'GIT DIFF'
# git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only

# First check whether changed files are in the path of tool requests.
# If so, we run the install script.  If not, exit 1.
# export CHANGED_FILES=$(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only | cat)
echo '0A'
echo $(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only)
echo '0B'
echo $(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only | cat | grep "^requests\/[^\/]*$")

echo '0C'
echo $(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only --diff-filter=A | cat)
echo '0D'
echo $(git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only --diff-filter=D)

echo '1 A pc c'
git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only --diff-filter=A  | cat | grep "^requests\/[^\/]*$"
echo '2 D pc c'
git diff $GIT_PREVIOUS_COMMIT $GIT_COMMIT --name-only --diff-filter=D | cat | grep "^requests\/[^\/]*$"

echo '3 A c pc'
git diff $GIT_COMMIT $GIT_PREVIOUS_COMMIT --name-only --diff-filter=A | cat | grep "^requests\/[^\/]*$"
echo '4 D c pc'
git diff $GIT_COMMIT $GIT_PREVIOUS_COMMIT  --name-only --diff-filter=D | cat | grep "^requests\/[^\/]*$"


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

echo 'Saving output to $LOG_FILE'
bash jenkins/webhook_install_tools.sh &> $LOG_FILE

cat $LOG_FILE
