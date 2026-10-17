"""Physical cross-host geometry, separate from each compositor's local coordinates."""
from pathlib import Path
import json,os
DEFAULT={'version':1,'homie':{'x':960,'y':-1080,'width':1920,'height':1080}}
def validate(value):
 if not isinstance(value,dict) or value.get('version')!=1:raise ValueError('Unsupported Den geometry')
 row=value.get('homie',{})
 if set(row)!=set(('x','y','width','height')):raise ValueError('Incomplete physical display')
 for key,v in row.items():
  if type(v) is not int or not (-16384<=v<=16384 if key in ('x','y') else 320<=v<=8192):raise ValueError('Invalid physical display coordinate')
 return {'version':1,'homie':dict(row)}
def load(home=None):
 path=Path(home or Path.home())/'.config/sensei-den/geometry.json'
 try:return validate(json.loads(path.read_text()))
 except FileNotFoundError:return validate(DEFAULT)
def ranges(geometry,main):
 r=validate(geometry)['homie'];mx,my,mw,mh=main
 left=max(mx,r['x']);right=min(mx+mw,r['x']+r['width'])
 if right<=left or r['y']+r['height']!=my:return {}
 return {'top':((left-mx)/mw,(right-mx)/mw),'bottom':((left-r['x'])/r['width'],(right-r['x'])/r['width'])}
def enter_ratio(geometry,coordinate,axis):
 r=validate(geometry)['homie'];return max(0,min(1,(coordinate-r['x' if axis=='x' else 'y'])/r['width' if axis=='x' else 'height']))
def return_coordinate(geometry,coordinate,axis):
 r=validate(geometry)['homie'];return r['x' if axis=='x' else 'y']+coordinate
