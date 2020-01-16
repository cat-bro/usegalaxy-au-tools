import re
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description='Mimic bash pattern matching')
    parser.add_argument('-p', '--pattern', help='Pattern to match')
    parser.add_argument('file_path', help='File in which to find first match')
    args = parser.parse_args()

    first_match_regex(args.file_path, args.pattern)

def first_match_regex(path, pattern):
    # Hack to return the same values that would be stored in BASH_REMATCH[1:] if
    # it were working on mac
    compiled_pattern = re.compile(
        pattern,
        # "(\w+) repositories \(1\): \[\('([^']+)',\s*u'(\w+)'\)\]",
        re.MULTILINE,
    )
    with open(path) as logfile:
        matches = compiled_pattern.findall(logfile.read())
        # print(matches)
    if len(matches) > 0:
        match = matches[0]
        sys.stdout.write('%s' % ' '.join(match))

if __name__ == "__main__": main()
