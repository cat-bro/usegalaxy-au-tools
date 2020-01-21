import argparse
import yaml
import sys

from bioblend import ConnectionError
from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.tools import ToolClient
from bioblend.galaxy.toolshed import ToolShedClient
from bioblend.toolshed import ToolShedInstance
from bioblend.toolshed.repositories import ToolShedRepositoryClient

mandatory_keys = [
'name', 'tool_panel_section_label', 'tool_shed_url', 'owner'
]
allowed_keys = ['revisions', 'ignore_test_errors']
forbidden_keys = ['tool_panel_section_id']

def main():
    parser = argparse.ArgumentParser(description="Lint tool input files for installation on Galaxy")
    parser.add_argument('-f', '--files', help='Tool input files', nargs='+')
    parser.add_argument('-u', '--staging_url', help='Galaxy staging server URL')
    parser.add_argument('-k', '--staging_api_key', help='API key for galaxy staging server')
    parser.add_argument('-g', '--production_url', help='Galaxy production server URL')
    parser.add_argument('-a', '--production_api_key', help='API key for galaxy production server')

    args = parser.parse_args()
    files = args.files
    staging_url = args.staging_url
    staging_api_key = args.staging_api_key
    production_url = args.production_url
    production_api_key = args.production_api_key

    loaded_files = yaml_check(args.files) # load yaml and raise ParserError if yaml is incorrect
    # flattened_tools = key_check(loaded_files) #
    # (installable_errors, requested_tools) = check_installable(flattened_tools)
    # installed_errors_staging = check_tools_against_panel(staging_url, staging_api_key, requested_tools)
    # installed_errors_production = check_tools_against_panel(production_url, production_api_key, requested_tools)
    key_check(loaded_files)
    tool_list = join_lists([x['yaml']['tools'] for x in loaded_files])
    installable_errors = check_installable(tool_list)
    installed_errors_staging = check_tools_against_panel(staging_url, staging_api_key, tool_list)
    installed_errors_production = check_tools_against_panel(production_url, production_api_key, tool_list)

    all_errors = installable_errors + installed_errors_staging + installed_errors_production
    if all_errors:
        sys.stderr.write('\n')
        for error in all_errors:
            sys.stderr.write('Error %s', error)
        raise Exception('Errors found')


def join_lists(list_of_lists):
    return [entry for list in list_of_lists for entry in list]

def flatten_tool_list(tool_list):
    flattened_tool_list = []
    for tool in tool_list:
        if tool['revisions']:
            for revision in tool['revisions']:
                copy_of_tool = tool.copy()
                copy_of_tool['revisions'] = revision
                flattened_tool_list.append(copy_of_tool)
        else:
            copy_of_tool = tool.copy()
            flattened_tool_list.append(copy_of_tool)
    return flattened_tool_list


def yaml_check(files):
    loaded_files = []
    for file in files:
        with open(file) as file_in:
            # As a first pass, check that yaml loads
            loaded_yml = yaml.safe_load(file_in.read()) # might throw exception here
            loaded_files.append({
                'yaml': loaded_yml,
                'filename': file,
            })
    return loaded_files

def key_check(loaded_files):  # TODO label check in this method
    flattened_tools = []
    for loaded_file in loaded_files:
        sys.stderr.write('Checking %s ... ' % loaded_file['filename'])
        if not 'tools' in loaded_file['yaml'].keys():
            system.out.write('ERROR\n')
            raise Exception('Expecting .yml file with \'tools\'. Check requests/template/template.yml for an example.')
        tools = loaded_file['yaml']['tools']
        if not isinstance(tools, list):
            tools = [tools]
        for key in mandatory_keys:
            for tool in tools:
                if not key in tool.keys():
                    system.out.write('ERROR\n')
                    raise Exception('All tool list entries must have \'%s\' specified. Check requests/template/template.yml for an example.' % key)
            if key == 'tool_panel_section_label':
                pass # TODO: Check that section label is valid
                #
        sys.stderr.write('OK\n')



# Use bioblend to check whether the package is already installed.  Need to do this without
# making the API keys public

# group tools by tool_shed_url


# get_ordered_installable_revisions(name, owner)

# Check that tools are installable according to bioblend.
def check_installable(tools):
    errors = []
    tools_by_shed = {}
    for tool in tool_list:
        if tool['tool_shed_url'] in tools_by_shed.keys():
            tools_by_shed[tool['tool_shed_url']].append(tool)
        else
            tools_by_shed[tool['tool_shed_url']] = [tool]

    requested_tools = []
    for shed in tools_by_shed.keys():
        toolshed = ToolShedInstance(url='https://%s' % shed)
        repo_client = ToolShedRepositoryClient(toolshed)

        for tool in tools_by_shed['shed']:
            try:
                installable_revisions = repo_client.get_ordered_installable_revisions(tool['name'], tool['owner'])
                installable_revisions = [str(r) for r in installable_revisions][::-1]  # un-unicode and list most recent first
                # TODO make absolutely sure that the ordering is now correct
                if not installable_revisions:
                    errors.append('Tool with name %s, owner %s and tool_shed_url %s has no installable revisions' % (tool['name'], tool['owner'], shed))
                    continue
                shed_status = 'online'
            except ConnectionError:
                print("Could not connect to toolshed")
                shed_status = 'offline'
                # Raise an exception?  Ask Simon.

            if tool['revisions']:  # Check that requested revisions are installable
                for revision in revisions:
                        if not revision in installable_revisions:
                            errors.append('% revision %s is not installable' % (tool['name'], revision))
                    # We can raise an exception here if revision is not installable
                    if shed_status = 'online':
                        # CHECK REVISION AGAINST installable_revisions
                    tool_revision = tool
                    tool_revision.update({'revision_request_type': 'specific', 'shed_status': shed_status})
                    tool_revision['revisions'] = [revision]
                    requested_tools.append(tool_revision)
            else:
                requested_tool = tool
                if shed_status = 'online':
                    requested_tool.update({'revisions': [installable_revisions[0]]})
                requested_tool.update({'revision_request_type': 'latest', 'shed_status': shed_status})
                requested_tools.append(requested_tool)

staging_galaxy_instance = GalaxyInstance(url=staging_url, key=staging_api_key)
production_galaxy_instance = GalaxyInstance(url=production_url, key=production_api_key)


def check_tools_against_panel(galaxy_url, galaxy_api_key, tools):
    galaxy_instance = GalaxyInstance(url=galaxy_url, key=galaxy_api_key)
    tool_client = ToolClient(galaxy_instance)
    panel = tool_client.get_tool_panel()
    requested_tools = flatten_tool_list(tools)

    errors = []
    # the tool panel returned is a list of sections.
    # each section is a dict, dict['elems'] is a list of installed tools
    for section in panel:
        for elem in section['elems']
            if 'tool_shed_repository' in elem.keys():
                repo = elem['tool_shed_repository']
                # tool is installed if 'name', 'owner' and 'revision' all match
                matching_tools = [tool for tool in requested_tools if tool['shed_status'] == 'online' and
                    (tool['name'], tool['owner'], tool['revisions'][0], tool['tool_shed_url']) ==
                    (repo['name'], repo['owner'], repo['changeset_revision'], repo['tool_shed'])
                ]
                if matching_tools:
                    errors.append(
                        'Tool with name: %s, owner %s, revision %s, tool_shed_url %s is already installed on %s' %
                        (tool['name'], tool['owner'], tool['revisions'][0], tool['tool_shed_url'], galaxy_url)
                    )
    return errors
