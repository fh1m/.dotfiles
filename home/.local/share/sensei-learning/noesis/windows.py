"""Machine-local window identities; never synced with learning content."""
import re
from pathlib import Path

def validate_id(value):
 if not isinstance(value,str) or not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}',value):raise ValueError('Invalid Noesis window identity')
 return value

def state_file(home,identity='main'):
 identity=validate_id(identity);root=Path(home)/'.local/state/sensei-learning'
 return root/'window.json' if identity=='main' else root/'windows'/(identity+'.json')

def merge_state(old,updates):
 return dict({'version':3,'placement':'current','return_behavior':'stay'},**old)|updates
