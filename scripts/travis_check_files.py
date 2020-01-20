import argparse
import yaml

parser = argparse.ArgumentParser(description="Uninstall tool from a galaxy instance")
parser.add_argument('-f', '--files', help='Tool input files', nargs='+')

args = parser.parse_args()
files = args.files

mandatory_keys = [
    'name', 'tool_panel_section_label', 'tool_shed_url', 'owner'
]

allowed_keys = ['revisions', 'ignore_test_errors']

forbidden_keys = ['tool_panel_section_id']


loaded_files = []
for file in files:
    with open(file) as file_in:
        # try:
        #     loaded_files.append(yaml.safe_load(file_in.read())) #############
        # except: #whatever happens when you get bad yaml
        #     return

        # Check that yaml loads first
        loaded_yml = yaml.safe_load(file_in.read()) # might throw exception here
        loaded_files.append({
            'yaml': loaded_yml,
            'filename': file,
        })

for loaded_file in loaded_files:
    sys.stderr.write('Checking %s ... ', loaded_file['filename'])
    if not 'tools' in loaded_file['yaml'].keys():
        system.out.write('ERROR\n')
        raise Exception('Expecting .yml file with \'tools\'. Check requests/template/template.yml for an example.')
    tools = loaded_file['yaml']['tools']
    if not isinstance(tools, list):
        tools = [tools]
    for key in mandatory_keys:
        for tool in tools:
            try:
                val = tool[key]
            except KeyError:
                system.out.write('ERROR\n')
                raise Exception('All tool list entries must have \'%s\' specified. Check requests/template/template.yml for an example.' % key)
