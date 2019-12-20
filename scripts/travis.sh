# echo $TRAVIS_COMMIT_RANGE
# echo $(git diff --name-only HEAD...$TRAVIS_BRANCH | cat)
# echo 'hi cat'
#
if [ ! $TRAVIS_PULL_REQUEST ]; then
  exit 0;
fi

# check the range of the commit input_file_paths
$REQUESTS_DIFF=$(git diff --name-only HEAD...$TRAVIS_BRANCH requests/ | cat | grep "^requests\/[^\/]*$")

if [ ! $REQUESTS_DIFF ]; then
  echo 'No changed files in requests directory - no tests for this case';
  exit 0;
fi

# pass the requests file paths to a python script that checks the yml
python scripts/travis_check_files.py --valid-yaml -f $(tr '\n' ' ' < $REQUESTS_DIFF)
