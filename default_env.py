import sys
import ruamel_yaml
home_dir = '/opt/continuum/project' if len(sys.argv) < 2 else sys.argv[1]
try:
    with open(home_dir.rstrip('/') + '/anaconda-project.yml', 'r') as fp:
        envs = ruamel_yaml.safe_load(fp).get('env_specs')
    result = []
    if not envs or 'default' in envs:
        result.append('default')
    result.extend(e for e in envs if e != 'default')
    print(' '.join(result))
except Exception as exc:
    print('ERROR: {}'.format(exc), file=sys.stderr)
    print('Could not determine the conda environment; please check anaconda-project.yml.', file=sys.stderr)
    print('@ERROR@')
