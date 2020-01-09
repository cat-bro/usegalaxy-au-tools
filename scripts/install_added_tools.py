import yaml
import argparse
import os
import logging

logger = logging.getLogger(__name__)

# def main():
#
#     VERSION = 0.1

parser = argparse.ArgumentParser(description='Run ephemeris shed_tools install for a list of input files')
parser.add_argument('-g', '--galaxy_server', help='Galaxy server URL')
parser.add_argument('-a', '--api_key', help='API key for galaxy server')
parser.add_argument('-f', '--files', help='Tool input files', nargs='+')
# parser.add_argument('-d', '--directory', help='Local directory of tool files')

args = parser.parse_args()

galaxy_server = args.galaxy_server
api_key = args.api_key
input_file_paths = args.files
# dir = args.directory
galaxy_tools_install_file = 'tmp/tools_to_install.yml'
galaxy_tools_output = 'installed_tools.yml'
shed_tools_log = 'tmp/shed_tools_install_output.txt'

print('input_file_paths: ', input_file_paths)

tools_to_install = []

for file in input_file_paths:
    with open(file) as input:
        content = yaml.safe_load(input.read())
        # if isinstance(content, list):
        tools_to_install += content['tools']
        # else:
        #     repository_state.append(content)

with open(galaxy_tools_install_file, 'w') as installfile:
    installfile.write(yaml.dump({'tools': tools_to_install}))


try:
    os.system('shed-tools install -g %s -a %s -t %s -v &> %s' % (galaxy_server, api_key, galaxy_tools_install_file, shed_tools_log))
    with open(shed_tools_log) as log_file:
        logger.info(log_file.read())
    # return 'OK'  # TODO: def main
except:
    error = sys.exc_info()[0]
    print("Unexpected error: ", error)
    # return error
    # raise

# command = 'get-tool-list --get_data_managers --include_tool_panel_id -g %s -a %s -o %s' % (galaxy_server, api_key, galaxy_tools_output)
# os.system(command)
# with open(galaxy_tools_output) as tool_list:
#     galaxy_state = yaml.safe_load(tool_list.read())['tools']
#
# repository_state = []
# files = os.listdir(dir)
# # print('files', files)
# for file in files:
#     with open(dir + '/' + file) as input:
#         content = yaml.safe_load(input.read())
#         # if isinstance(content, list):
#         repository_state += content['tools']
#         # else:
#         #     repository_state.append(content)
#
# # print(repository_state)
#
# tools_to_install = []
# for entry in repository_state:
#
#     # name and revision must match output of get_tool_list, else we install it
#     # print(entry['name'])
#     name = entry['name']
#     revisions = entry['revisions']
#     owner = entry['owner'] # does owner need to match?
#
#     galaxy_tools = [tool for tool in galaxy_state if tool['name'] == name]
#
#     if not galaxy_tools:
#         tools_to_install.append(entry)
#         break
#
#     galaxy_tool = galaxy_tools[0] # make this whole block a function
#
#     uninstalled_revisions = list(set(galaxy_tool['revisions']) - set(revisions))
#     if uninstalled_revisions:
#         entry['revisions'] = uninstalled_revisions
#         tools_to_install.append(entry)
#
# if not tools_to_install:
#     print('No new tools to install')
# else:
#     with open(galaxy_tools_install_file, 'w') as installfile:
#         installfile.write(yaml.dump({'tools': tools_to_install}))
#     os.system('shed-tools install -g %s -a %s -t %s -v' % (galaxy_server, api_key, galaxy_tools_install_file))

# for tool in input_list:
#     os.system('shed-tools install -g %s -a %s -t %s -v' % (galaxy_server, api_key, galaxy_tools_install_file))
