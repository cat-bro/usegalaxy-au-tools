# echo $TRAVIS_COMMIT_RANGE
# echo $(git diff --name-only HEAD...$TRAVIS_BRANCH | cat)
# echo 'hi cat'
#

jenkins_dirs=$('galaxy-aust-staging' 'galaxy-aust-dev' 'usegalaxy.org.au' 'cat-dev')  #this is not very satisfying for the regex matching

if [ ! $TRAVIS_PULL_REQUEST ]; then
  exit 0;
fi

# check the range of the commit input_file_paths
$CHANGED_FILES=$(git diff --name-only HEAD...$TRAVIS_BRANCH | cat)
$REQUEST_FILES=$($CHANGED_FILES | grep "^requests\/[^\/]*$")
# $JENKINS_CONTROLLED_FILES=$($CHANGED_FILES | grep "^requests\/[^\/]*$")
$(cat $CHANGED_FILES | grep "^requests\/[^\/]*$")

if [ $JENKINS_CONTROLLED_FILES ]; then
  echo 'Files within $jenkins_dirs are written by Jenkins and cannot be altered';
  exit 1;
fi

if [ ! $REQUEST_FILES ]; then
  echo 'No changed files in requests directory: there are no tests for this scenario';
  exit 0;
fi

# pass the requests file paths to a python script that checks the yml
python scripts/travis_check_files.py --valid-yaml -f $(tr '\n' ' ' < $REQUESTS_DIFF)
