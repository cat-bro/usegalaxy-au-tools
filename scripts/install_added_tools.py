import yaml
import argparse
import os
import logging
import sys
import re

logger = logging.getLogger(__name__)

def main():
    VERSION = 'development'

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
    shed_tools_test_log = 'tmp/shed_tools_test_output.txt'
    shed_tools_test_json = 'tmp/shed_tools_test.json'

    for file in [shed_tools_log, shed_tools_test_log, shed_tools_test_json]:
        os.system('rm %s' % file)  # TODO move this to the end of the script

    if len(input_file_paths) == 1:
        [galaxy_tools_install_file] = input_file_paths
    else:
        gather_inputs(input_file_paths, galaxy_tools_install_file)

    # try:

    # (1) Install tool on staging server

    command = (
        'shed-tools install -g %s -a %s -t %s -v --log_file %s --skip_install_resolver_dependencies False --skip_install_repository_dependencies False' %
        (galaxy_server, api_key, galaxy_tools_install_file, shed_tools_log)
    )
    sys.stderr.write(command + '\n')
    os.system(command)
    with open(shed_tools_log) as log_file:
        sys.stderr.write(log_file.read())
    result = verify_shed_tools_installation(shed_tools_log)
    sys.stderr.write(str(result) + '\n')
    if not (result and result['status'] == 'installed'):
        raise Exception('Installation status is %s.  Halting.' % result['status'])
        # (error): roll back installation, move file, log entry
    else:
        sys.stderr.write('Successfully installed %s at revision %s\n' % (result['name'], result['revision']))

    # (2) Run tests on staging server

    sys.stderr.write('Running tests\n')
    with open(galaxy_tools_install_file) as oops: # TODO This is no good
        owner = yaml.safe_load(oops.read())['tools'][0]['owner']
    os.system(
        'shed-tools test -g %s -a %s --name %s --owner %s --test_json %s -v --log_file %s' %
        (galaxy_server, api_key, result['name'], owner, shed_tools_test_json, shed_tools_test_log)
    )
    with open(shed_tools_test_log) as log_file:
        sys.stderr.write(log_file.read())
    # TODO: Check log file to see if tests have passed, if not raise exception and uninstall


def verify_shed_tools_installation(log_path):
    # actually just read the output and decide whether it has been installed
    # the assumption is that only one tool has been fed to shed_tools
    # TODO capture error message when there is one
    # TODO capture the phrase 'already installed'
    status_name_version_pattern = re.compile(
        "(\w+) repositories \(1\): \[\('([^']+)',\s*u'(\w+)'\)\]",
        re.MULTILINE,
    )
    with open(log_path) as logfile:
        matches = status_name_version_pattern.findall(logfile.read())
    print(matches)
    if len(matches) == 1:
        [match] = matches
        status = match[0].lower()
        name = match[1]
        revision = match[2]
        return {
            'status': status,
            # 'already_installed': already_installed,
            'name': name,
            'revision': revision,
        }
    else:
         sys.stderr.write('Error: unable to verify shed-tools installation')
         sys.stderr.write('%d matches found for search pattern' % len(matches))

def gather_inputs(input_file_paths, galaxy_tools_install_file):
    # TODO: This is not the right approach.  It will be best to split the files
    # into separate files in requests/pending, then run the install pipeline on
    # one at a time.
    tools_to_install = []
    for file in input_file_paths:
        with open(file) as input:
            content = yaml.safe_load(input.read())
            tools_to_install += content['tools']
    with open(galaxy_tools_install_file, 'w') as installfile:
        installfile.write(yaml.dump({'tools': tools_to_install}))

def wind_back_installation():
    pass

    # uninstall_tool

if __name__ == "__main__": main()

# except:
#     error = sys.exc_info()[0]
#     print("Unexpected error: ", error)
#     # return error
#     # raise


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
