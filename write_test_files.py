import yaml

stats_file = 'usegalaxy.org.au/statistics.yml'
# stats_file = 'usegalaxy.org.au/assembly.yml'

tool_yamls=[]
commands=[]
start = 0
limit = None

G = 'https://galaxy-cat.genome.edu.au'
A = '34d089b5461a63a9674bd6e97b07daae'

with open(stats_file) as stats:
    tools = yaml.safe_load(stats.read())['tools']

for tool in tools:
    del tool['revisions']
    del tool['tool_panel_section_id']
    name = tool['name']
    filename = 'test_install/%s.yml' % name
    with open(filename, 'w') as single_file:
        single_file.write(yaml.dump({'tools': [tool]}))
    commands.append({
        'command': 'python scripts/install_added_tools.py -g %s -a %s -f %s' % (G, A, filename),
        'filename': filename,
    })

with open('test_multiple.sh', 'w') as bashfile:
    for command in (commands[start:start+limit] if limit else commands[start:]):
        bashfile.write('echo \'****** %s\'\n' % command['filename'])
        bashfile.write(command['command'] + '\n')

with open('uninstall_multiple.sh', 'w') as uninstall_file:
    uninstall_file.write(
        'python scripts/uninstall_tools.py -g %s -a %s -n %s' %
        (G, A, ' '.join([tool['name'] for tool in tools]))
    )
