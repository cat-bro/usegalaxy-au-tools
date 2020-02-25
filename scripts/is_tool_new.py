import sys
import argparse

from bioblend.galaxy import GalaxyInstance
from bioblend.galaxy.toolshed import ToolShedClient


def main():
    parser = argparse.ArgumentParser(description='Uninstall tool from a galaxy instance')
    parser.add_argument('-g', '--galaxy_url', help='Galaxy server URL')
    parser.add_argument('-a', '--api_key', help='API key for galaxy server')
    parser.add_argument('-n', '--name', help='Tool name')
    parser.add_argument('-o', '--owner', help='Tool owner', action='store_true')

    args = parser.parse_args()
    galaxy_url = args.galaxy_url
    api_key = args.api_key
    name = args.names
    owner = args.force

    gal = GalaxyInstance(galaxy_url, api_key)
    cli = ToolShedClient(gal)
    u_repos = cli.get_repositories()
    tools_with_name_and_owner = [t for t in u_repos if str(t['name'] == name and str(t['owner'] == owner))]
    if not tools_with_name_and_owner:
        sys.stdout.write('T')  # we did not find the name/owner combination so we say that the tool is new
    else:
        sys.stdout.write('F')


if __name__ == "__main__":
    main()
