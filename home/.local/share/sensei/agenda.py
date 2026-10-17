"""Read-only agenda projection. Source records remain editable only in their owner."""
import datetime,hashlib,json,sqlite3,sys
from pathlib import Path

def learning(home=Path.home()):
 sys.path.insert(0,str(home/'.local/share/sensei-learning'))
 from noesis.scopes import locations
 from noesis.persistence import manifest_path
 from noesis.activities import review_heads
 result=[]
 for root in locations():
  try:
   manifest=json.loads(manifest_path(root).read_text());vault=manifest['vault_id']
   cache=home/'.cache/noesis'/(hashlib.sha256(str(root.resolve()).encode()).hexdigest()+'.sqlite')
   if not cache.exists():continue
   db=sqlite3.connect(cache.as_uri()+'?mode=ro',uri=True,timeout=1)
   try:
    identities={r[0]:dict(title=r[1],path=r[2]) for r in db.execute('select id,title,path from records')}
    grouped={}
    for target,raw in db.execute('select target,props from activities order by timestamp'):
     grouped.setdefault(target,[]).append(json.loads(raw))
   finally:db.close()
   for target,timeline in grouped.items():
    heads=review_heads(timeline)
    if len(heads)!=1:continue  # Conflicting plans need resolution in Noesis, not a guessed calendar date.
    plan=heads[0]
    if plan.get('action')=='retire' or not plan.get('due') or target not in identities:continue
    if any(x.get('review_plan_id')==plan['id'] and x.get('event') in ('attempt','review') and x.get('outcome') in ('failed','partial','succeeded') for x in timeline):continue
    date=datetime.datetime.fromisoformat(plan['due'].replace('Z','+00:00')).astimezone()
    record=identities[target]
    result.append(dict(uid='noesis:'+vault+':'+plan['id'],source='noesis',title=record['title'],date=date.date().isoformat(),time=date.strftime('%H:%M'),due=date.timestamp(),vault=str(root),vault_id=vault,record_id=target,read_only=True,category='Learning review'))
  except (OSError,ValueError,KeyError,sqlite3.Error):continue
 return result
