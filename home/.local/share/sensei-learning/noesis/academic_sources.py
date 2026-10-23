"""Bounded official-source refresh. Changes are staged, never silently promoted."""
import datetime,hashlib,json,urllib.request,urllib.error
from pathlib import Path
from .persistence import publish
SOURCES={'curriculum':'https://cse.uiu.ac.bd/ug-program/course-plan/','descriptions':'https://cse.uiu.ac.bd/ug-program/course-description/','calendar':'https://www.uiu.ac.bd/academics/calendar/','notices':'https://cse.uiu.ac.bd/notice/','grading':'https://www.uiu.ac.bd/academics/grading-performance-evaluation/','policies':'https://www.uiu.ac.bd/academics/academic-information-policies/'}
def calendar():return json.loads((Path(__file__).resolve().parents[1]/'catalogs/uiu-fall-2026-calendar.json').read_text())
def status():
 p=Path.home()/'.local/state/noesis-academic-sources/status.json';return json.loads(p.read_text()) if p.exists() else {'sources':[],'message':'No direct refresh yet; indexed official snapshots are labelled separately'}
def refresh():
 root=Path.home()/'.local/state/noesis-academic-sources';root.mkdir(parents=True,exist_ok=True,mode=0o700);root.chmod(0o700);rows=[]
 for key,url in SOURCES.items():
  checked=datetime.datetime.now(datetime.timezone.utc).isoformat()
  try:
   with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Noesis personal academic source monitor'}),timeout=8) as response:raw=response.read(4*1024*1024+1)
   if len(raw)>4*1024*1024:raise ValueError('Oversized source response')
   sha=hashlib.sha256(raw).hexdigest();folder=root/key;folder.mkdir(exist_ok=True)
   target=folder/(sha+'.html')
   if not target.exists():publish(target,raw.decode('utf-8'))
   rows.append({'key':key,'url':url,'checked_at':checked,'sha256':sha,'status':'staged-review','message':'Compare against the accepted version before changing dates or degree rules'})
  except (OSError,ValueError,UnicodeError,urllib.error.URLError):rows.append({'key':key,'url':url,'checked_at':checked,'status':'unavailable','message':'Accepted data preserved; retry later or inspect official source manually'})
 path=root/'status.json';text=json.dumps({'sources':rows},indent=2)+'\n';publish(path,text,hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None)
 return {'sources':rows}
def export_ics(destination):
 data=calendar();lines=['BEGIN:VCALENDAR','VERSION:2.0','PRODID:-//Noesis//UIU academic sources//EN','X-WR-CALNAME:UIU BSCSE Undergraduate Fall 2026']
 for e in data['events']+data.get('withdrawn_events',[]):
  lines+=['BEGIN:VEVENT','UID:'+e['uid'],'SEQUENCE:'+str(e['sequence']),'DTSTART;VALUE=DATE:'+e['start'].replace('-','')]
  if e.get('end'):lines+=['DTEND;VALUE=DATE:'+e['end'].replace('-','')]
  if e['status']=='withdrawn-unverified':lines+=['STATUS:CANCELLED']
  lines+=['SUMMARY:'+e['title'],'DESCRIPTION:'+e['source']+' — '+e['status'],'END:VEVENT']
 lines+=['END:VCALENDAR'];Path(destination).write_text('\r\n'.join(lines)+'\r\n');return {'path':str(destination),'events':len(data['events']),'withdrawn':len(data.get('withdrawn_events',[])),'coverage':data['coverage']}
