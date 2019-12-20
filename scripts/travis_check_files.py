import argparse
import yaml

parser = argparse.ArgumentParser(description="Uninstall tool from a galaxy instance")
parser.add_argument('-f', '--files', help='Tool input files', nargs='+')

args = parser.parse_args()
files = args.files

loaded_ymls = []
for file in files:
    with open(file) as file_in:
        loaded_ymls.append(yaml.safe_load(file_in.read()))
