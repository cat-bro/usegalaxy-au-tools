#!/usr/bin/env python

import yaml
import argparse
import os

# def main():
#
#     VERSION = 0.1

parser = argparse.ArgumentParser(description="Splits up a Ephemeris `get_tool_list` yml file for a Galaxy server into individual files for each Section Label.")
parser.add_argument("-g", "--galaxy_server", help="Galaxy server URL")
parser.add_argument("-a", "--api_key", help="API key for galaxy server")
parser.add_argument("-d", "--directory", help="Local directory of tool files")

args = parser.parse_args()

galaxy_server = args.galaxy_server
api_key = args.api_key
dir = args.directory
galaxy_tools_install_file = 'tools_to_install.yml'
galaxy_tools_output = 'installed_tools.yml'

command = 'get-tool-list --get_data_managers --include_tool_panel_id -g %s -a %s -o %s' % (galaxy_server, api_key, galaxy_tools_output)
os.system(command)
with open(galaxy_tools_output) as tool_list:
    galaxy_state = yaml.safe_load(tool_list.read())['tools']

repository_state = []
files = os.listdir(dir)
# print('files', files)
for file in files:
    with open(dir + '/' + file) as input:
        content = yaml.safe_load(input.read())
        # if isinstance(content, list):
        repository_state += content['tools']
        # else:
        #     repository_state.append(content)

# print(repository_state)

tools_to_install = []
for entry in repository_state:

    # name and revision must match output of get_tool_list, else we install it
    # print(entry['name'])
    name = entry['name']
    revisions = entry['revisions']
    owner = entry['owner'] # does owner need to match?

    galaxy_tools = [tool for tool in galaxy_state if tool['name'] == name]

    if not galaxy_tools:
        tools_to_install.append(entry)
        break

    galaxy_tool = galaxy_tools[0] # make this whole block a function

    uninstalled_revisions = list(set(galaxy_tool['revisions']) - set(revisions))
    if uninstalled_revisions:
        entry['revisions'] = uninstalled_revisions
        tools_to_install.append(entry)

if not tools_to_install:
    print('No new tools to install')
else:
    with open(galaxy_tools_install_file, 'w') as installfile:
        installfile.write(yaml.dump({'tools': tools_to_install}))
    os.system('shed-tools install -g %s -a %s -t %s -v' % (galaxy_server, api_key, galaxy_tools_install_file))
