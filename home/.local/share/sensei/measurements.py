"""Small explicit measurement contract; execution success is not hypothesis acceptance."""
import math

def validate(rows):
 if not isinstance(rows,list) or len(rows)>1000:raise ValueError('Expected at most 1000 measurements')
 seen=set();out=[]
 for row in rows:
  if not isinstance(row,dict) or set(row)-{'name','value','unit','step'}:raise ValueError('Unknown measurement fields')
  name=row.get('name');value=row.get('value');unit=row.get('unit');step=row.get('step')
  if not isinstance(name,str) or not name.strip() or len(name)>120:raise ValueError('Measurement needs a name')
  if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value):raise ValueError('Measurement must be a finite number')
  if not isinstance(unit,str) or not unit.strip() or len(unit)>40:raise ValueError('Measurement needs a unit (use dimensionless when appropriate)')
  if step is not None and (isinstance(step,bool) or not isinstance(step,int) or step<0):raise ValueError('Invalid measurement step')
  key=(name,step)
  if key in seen:raise ValueError('Duplicate measurement and step')
  seen.add(key);out.append(dict(row))
 return out

def compare(current,baseline):
 current=validate(current);baseline=validate(baseline);lookup={(x['name'],x.get('step')):x for x in baseline};out=[]
 for row in current:
  old=lookup.get((row['name'],row.get('step')))
  if not old:out.append(dict(name=row['name'],state='missing-baseline'));continue
  if old['unit']!=row['unit']:out.append(dict(name=row['name'],state='incompatible-units'));continue
  out.append(dict(name=row['name'],unit=row['unit'],current=row['value'],baseline=old['value'],delta=row['value']-old['value'],state='comparable'))
 return out
