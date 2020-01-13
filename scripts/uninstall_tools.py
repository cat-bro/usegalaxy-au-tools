from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.tools import ToolClient
from bioblend.galaxy.toolshed import ToolShedClient
import argparse
import yaml
import os
import sys

"""
Uninstall tools from a galaxy instance via the API using the bioblend package.
This can be used to uninstall any galaxy toolshed tool.  The main use case is
when a tool has been installed incorrectly or when an error has occurred during
installation causing the tool to be partially installed.
"""

def main():
    parser = argparse.ArgumentParser(description="Uninstall tool from a galaxy instance")
    parser.add_argument("-g", "--galaxy_server", help="Galaxy server URL")
    parser.add_argument("-a", "--api_key", help="API key for galaxy server")
    # parser.add_argument('-f', '--files', help='Tool input files', nargs='+')
    parser.add_argument('-n', '--names', help='Names of tools to uninstall', nargs='+') # default uninstall all tools in list

    args = parser.parse_args()
    galaxy_server = args.galaxy_server
    api_key = args.api_key
    # files = args.files
    names = args.names

    # if not (names or files):
    #     raise Exception('At least one of arguments --names (-n) or --files (-f) must be provided.')

    if not names:
        raise Exception('Arguments --names (-n) must be provided.')

    uninstall_tools(galaxy_server, api_key, names, files=None)
    # print('names: ', names, 'files: ', files)
    # print('names: ', names)

def uninstall_tools(galaxy_server, api_key, names, files):
    temp_tool_list_file = 'tmp/tool_list.yml' # TODO datetime on this filename
    # TODO: Switch to using bioblend to obtain this list
    # ephemeris uses bioblend but without using ephemeris we cut out the need to for a temp file
    os.system('get-tool-list -g %s -a %s -o %s --get_all_tools' % (galaxy_server, api_key, temp_tool_list_file))

    tools_to_uninstall = []
    with open(temp_tool_list_file) as tool_file:
        installed_tools = yaml.safe_load(tool_file.read())['tools']
    if not installed_tools:
        raise Exception('No tools to uninstall')
    os.system('rm %s' % temp_tool_list_file)

    galaxy_instance = GalaxyInstance(url=galaxy_server, key=api_key)
    tool_client = ToolClient(galaxy_instance)
    toolshed_client = ToolShedClient(galaxy_instance)

    for name in names:
        tools_with_name = [t for t in installed_tools if t['name'] == name]
        if len(tools_with_name) > 1:
            raise Exception('More than one tool found with name ', name)
        elif len(tools_with_name) == 0:
            sys.stderr.write('*** Warning: No tool with name %s\n' % name)
            #raise Exception('No tool with name ', name)
        else: # Unique tool to uninstall
            tool = tools_with_name[0]
            tools_to_uninstall.append(tool)

    for tool in tools_to_uninstall:
        try:
            name = tool['name']
            owner = tool['owner']
            tool_shed_url = tool['tool_shed_url']
            revision = tool['revisions'][0] # TODO handle the case of multiple revisions
            if name in names or names is None:
                print('Uninstalling ', name)
                return_value = toolshed_client.uninstall_repository_revision(name=name, owner=owner, changeset_revision=revision, tool_shed_url=tool_shed_url)
                print(return_value)
        except KeyError as e:
            print(e)

if __name__ == "__main__": main()

# This below is absurd.  It is needlessly complicated.  All it actually needs to do is
# use the 'name' case as a subroutine.  Not writing anymore, will fix later

# for file in files:
#     # match as many details as are provided out of
#     # 'name', 'owner', 'tool_shed_url'
#     # 'revisions' may be 'all' or a list of installed revisions
#     with open(file) as file_in:
#         file_tools = yaml.safe_load(file_in.read())['tools']
#         for tool in file_tools:
#             name = tool['name'] # TODO handle exception if absent, KeyError is fine for now
#             owner = tool.get('owner')
#             tool_shed_url = tool.get('tool_shed_url')
#             def match_entry(tool_dict):
#                 if(
#                     tool_dict['name'] != name
#                     or owner and tool_dict['owner'] != owner
#                     or tool_shed_url and tool_dict['tool_shed_url'] != tool_shed_url
#                 ):
#                     return False
#                 return True
#             matched_tools = [t for t in installed_tools if match_entry(t)]
#             # TODO Handle multiple matches or no matches here
#             tool_to_uninstall = matched_tools[0]
#             installed_revisions = tool_to_uninstall.get('revisions')
#             revisions_to_uninstall = tool.get('revisions')
#             if len(installed_revisions) > 1: # don't worry about checking hashes if there is only one revision
#                 if revisions_to_uninstall != 'all':
#                 if not set(revisions_to_uninstall).issubset(set(installed_revisions)):
#                     raise Exception(
#                         'The following specified revisions of %s are not installed:\n%s'
#                         % (name, )
#             #if tool['name'] in names or names is None:  # need to check for key error
#                 try: # TODO: is there a shapelier way to do this?
#                     name = tool['name']
#                     owner = tool['owner']
#                     # tool_panel_section_label = tool['tool_panel_section_label']
#                     tool_shed_url = tool['tool_shed_url']
#                     revision = tool['revisions'][0] # TODO we will almost certainly be getting this from get_tool_panel or get_tools
