#!/usr/bin/env python

import yaml
import argparse
import os

def main():

    VERSION = 0.1

    parser = argparse.ArgumentParser(description="Splits up a Ephemeris `get_tool_list` yml file for a Galaxy server into individual files for each Section Label.")
    parser.add_argument("-g", "--galaxy_server", help="Galaxy server URL")
    parser.add_argument("-a", "--api_key", help="API key for galaxy server")
    paser.add_argument("-d", "--directory", help="Local directory of tool files")

    args = parser.parse_args()

    galaxy_server = args.galaxy_server
    api_key = args.api_key
    dir = args.directory
    tools_output_dir = 'tmp/installed_tools.yml'

    repository_state = [] # list of yamls, there must be a better way
    files = os.listdir(dir)
    for file in files:
        repository_state.append(yaml.load('dir/' + file))

    print(files)
