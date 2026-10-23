"""Source-versioned degree facts and append-only private academic records."""
import datetime,json,uuid,math
from collections import defaultdict
from pathlib import Path
from .persistence import lock,publish
GRADES={'A':4.,'A-':3.67,'B+':3.33,'B':3.,'B-':2.67,'C+':2.33,'C':2.,'C-':1.67,'D+':1.33,'D':1.,'F':0.}
KINDS=('enrollment','result','attendance','assessment','override','timetable')
def catalog():return json.loads((Path(__file__).resolve().parents[1]/'catalogs/uiu-bscse-2026.json').read_text())
def normalize(code):return ''.join(str(code).upper().split())
def records(root):
 folder=Path(root)/'System/Academic/events'
 return sorted([json.loads(p.read_text()) for p in folder.glob('*.json')],key=lambda r:(r['created'],r['id']))
def record(root,kind,data,operation):
 uuid.UUID(operation)
 if kind not in KINDS or not isinstance(data,dict):raise ValueError('Unsupported academic record')
 c=catalog();courses={r['code']:r for r in c['courses']};data=dict(data);data['course']=normalize(data.get('course',''))
 if data['course'] not in courses:raise ValueError('Choose a known curriculum course')
 if not data.get('term') or len(data['term'])>80:raise ValueError('A trimester is required')
 if kind=='result' and data.get('grade') not in GRADES:raise ValueError('Use an official letter grade; estimates belong in assessments')
 if kind=='attendance':
  if data.get('state') not in ('attended','absent','unknown','cancelled'):raise ValueError('Invalid attendance state')
  datetime.date.fromisoformat(data['date'])
 if kind=='override' and not str(data.get('reason','')).strip():raise ValueError('An override must preserve its reason')
 if kind=='enrollment' and data.get('status') not in ('planned','registered','withdrawn','completed','failed','waived'):raise ValueError('Invalid enrollment status')
 if kind=='enrollment' and data.get('status')=='waived' and (data.get('approved') is not True or not data.get('evidence')):raise ValueError('Waivers need recorded official approval and evidence')
 if kind=='assessment':assessment_summary([data])
 if kind=='timetable':
  if data.get('day') not in range(7):raise ValueError('Weekday must be 0 (Monday) through 6')
  datetime.time.fromisoformat(data['start']);datetime.time.fromisoformat(data['end'])
 path=Path(root)/'System/Academic/events'/(operation+'.json');value={'version':1,'id':operation,'kind':kind,'data':data,'created':datetime.datetime.now(datetime.timezone.utc).isoformat(),'curriculum_sha256':c['source']['sha256']}
 with lock(root):
  if path.exists():
   old=json.loads(path.read_text())
   if old['kind']!=kind or old['data']!=data:raise ValueError('Academic operation ID reused with changed data')
   return old
  if kind=='assessment':
   existing={}
   for event in records(root):
    d=event['data']
    if event['kind']=='assessment' and d['course']==data['course'] and d['term']==data['term']:existing[d.get('name',event['id'])]=d
   existing[data.get('name',operation)]=data;assessment_summary(list(existing.values()))
  publish(path,json.dumps(value,ensure_ascii=False,indent=2)+'\n')
 return value

def assessment_summary(items):
 total=earned=remaining=0.
 for item in items:
  weight=item.get('weight',0);maximum=item.get('maximum',100);score=item.get('score')
  if not all(type(x) in (float,int) and math.isfinite(x) for x in (weight,maximum)) or not 0<weight<=100 or maximum<=0:raise ValueError('Assessment requires finite weight and positive maximum')
  total+=weight
  if score is None:remaining+=weight
  elif type(score) not in (float,int) or not math.isfinite(score) or not 0<=score<=maximum:raise ValueError('Assessment score is out of range')
  else:earned+=score/maximum*weight
 if total>100.00001:raise ValueError('Assessment weights exceed 100%')
 return {'earned_points':earned,'remaining_weight':remaining+max(0,100-total),'final':False,'label':'Scenario, not an official grade'}

def audit(root):
 c=catalog();courses={r['code']:r for r in c['courses']};events=records(root);results=[e for e in events if e['kind']=='result' and e['data'].get('confirmed') is True]
 grouped=defaultdict(list);enrollments={};attendance=defaultdict(lambda:defaultdict(int));assessments=defaultdict(dict);attendance_latest={}
 for e in events:
  d=e['data'];key=d['term']+':'+d['course']
  if e['kind']=='enrollment':enrollments[key]=d
  if e['kind']=='attendance':attendance_latest[(key,d['date'],d.get('session','default'))]=d['state']
  if e['kind']=='assessment':assessments[key][d.get('name',e['id'])]=d
 for (key,date,session),state in attendance_latest.items():attendance[key][state]+=1
 for e in results:grouped[e['data']['course']].append(e['data'])
 earned={k for k,v in grouped.items() if any(GRADES[d['grade']]>=1 for d in v)}
 earned.update(d['course'] for d in enrollments.values() if d.get('status')=='waived' and d.get('approved') is True and d.get('evidence'))
 # Credits count once. Repeated results cannot silently choose a GPA policy.
 repeated=any(len(v)>1 for v in grouped.values());credits=sum(courses[k]['credits'] for k in grouped)
 cgpa=None if repeated or not credits else sum(courses[k]['credits']*GRADES[v[0]['grade']] for k,v in grouped.items())/credits
 buckets={};counted=0
 for key in ('language','general-required','science','math','engineering','core','fydp','general-elective','elective'):
  amount=sum(courses[k]['credits'] for k in earned if courses[k]['bucket']==key);target=c['baskets'].get(key,sum(r['credits'] for r in courses.values() if r['bucket']==key));buckets[key]={'earned':amount,'required':target,'applied':min(amount,target)};counted+=min(amount,target)
 attendance_rows=[]
 for key,v in attendance.items():
  known=v['attended']+v['absent'];attendance_rows.append({'key':key,**v,'known_percent':100*v['attended']/known if known else None,'uncertain':v['unknown']>0})
 warnings=list(c['issues'])
 for key,d in enrollments.items():
  missing=[p for p in courses[d['course']]['prerequisites'] if p not in earned]
  if d.get('status') not in ('planned','registered'):continue
  if missing:warnings.append({'course':d['course'],'term':d['term'],'missing_prerequisites':missing,'severity':'warning','override_available':True})
 for a in attendance_rows:
  if a['known_percent'] is not None and a['known_percent']<80:warnings.append({'attendance':a['key'],'recorded_percent':a['known_percent'],'threshold':80,'uncertain':a['uncertain'],'source':c['attendance_policy_source'],'severity':'warning'})
 tracks={t:len({k for k in earned if courses[k]['bucket']=='elective' and t in courses[k]['tracks']}) for r in courses.values() for t in r['tracks']}
 return {'specialization_courses':tracks,'fydp_minimum_grade':'C','fydp_completed_stages':len([k for k in earned if courses[k]['bucket']=='fydp']),'program':c['program'],'cohort':'Fall 2026','curriculum':c['effective_from'],'degree_credits':141,'earned_credits':counted,'remaining_credits':max(0,141-counted),'cgpa':cgpa,'cgpa_status':'unresolved retake policy; confirm official transcript' if repeated else 'calculated from confirmed entered results; not an official transcript','result_count':len(results),'buckets':buckets,'enrollments':list(enrollments.values()),'attendance':attendance_rows,'assessments':{k:assessment_summary(list(v.values())) for k,v in assessments.items()},'warnings':warnings,'overrides':[e for e in events if e['kind']=='override'],'events':events,'competence_awarded':False,'source':c['source']}

def study(root,course,term):
 from .models import create
 c=catalog();course=normalize(course);row=next((r for r in c['courses'] if r['code']==course),None)
 if not row:raise ValueError('Unknown curriculum course')
 operation=str(uuid.uuid5(uuid.NAMESPACE_URL,'noesis:UIU:BSCSE:Summer2026:'+term+':'+course))
 result=create(Path(root),'resource',row['display_code']+' · '+term,'Academic learning workspace. Enrollment and course completion are separate from independent understanding.\n\nSource: '+c['source']['url']+'\n',fields={'source_kind':'course','academic_course':course,'academic_term':term,'source':c['source']['url']},operation_id=operation)
 return dict(result,title=row['display_code']+' · '+term,type='resource',source_kind='course')


def configure(root,home=None):
 from .scopes import identity,assert_unique
 root=Path(root).resolve();assert_unique(root);value=identity(root)
 if not value:raise ValueError('Register a managed vault with a stable identity first')
 path=Path(home or Path.home())/'.config/noesis/academic.json';path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
 text=json.dumps({'version':1,'vault_id':value})+'\n'
 publish(path,text,__import__('hashlib').sha256(path.read_bytes()).hexdigest() if path.exists() else None);path.chmod(0o600)
 return {'configured':True,'vault_id':value}

def owner(home=None):
 from .scopes import locations,identity
 path=Path(home or Path.home())/'.config/noesis/academic.json'
 if not path.exists():raise ValueError('Choose the private academic owner with noesis academic configure --vault PATH')
 value=json.loads(path.read_text());matches=[p for p in locations() if identity(p)==value['vault_id']]
 if len(matches)!=1:raise ValueError('Academic owner is missing or ambiguous; register its canonical local replica')
 return matches[0]
