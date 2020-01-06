# echo $TRAVIS_COMMIT_RANGE
# echo $(git diff --name-only HEAD...$TRAVIS_BRANCH | cat)

STAGING_DIR='galaxy-cat'  # TODO: when using this in production swap this to 'galaxy-aust-staging' (commented out below)
PRODUCTION_DIR='cat-dev'  # TODO: when using this in production swap this to 'usegalaxy.org.au' (commented out below)

# STAGING_DIR='galaxy-aust-staging'
# PRODUCTION_DIR='usegalaxy.org.au'

if [ ! $TRAVIS_PULL_REQUEST ]; then
  exit 0;
fi

# check the range of the commit input_file_paths
CHANGED_FILES=$(git diff --name-only HEAD...$TRAVIS_BRANCH)
echo ________________
echo $CHANGED_FILES
echo ________________
REQUEST_FILES=$($CHANGED_FILES | grep "^requests\/[^\/]*$")
JENKINS_CONTROLLED_FILES=$($CHANGED_FILES | grep "^(?:\$STAGING_DIR\/|PRODUCTION_DIR\/).*/")
# $JENKINS_CONTROLLED_FILES=$($CHANGED_FILES | grep "^requests\/[^\/]*$")
$(cat $CHANGED_FILES | grep "^requests\/[^\/]*$")

if [ $JENKINS_CONTROLLED_FILES ]; then
  echo 'Files within $PRODUCTION_DIR or $STAGING_DIR are written by Jenkins and cannot be altered';
  exit 1;
fi

if [ ! $REQUEST_FILES ]; then
  echo 'No changed files in requests directory: there are no tests for this scenario';
  exit 0;
fi

# pass the requests file paths to a python script that checks the yml
python scripts/travis_check_files.py --valid-yaml -f $(tr '\n' ' ' < $REQUESTS_DIFF)
