#!/usr/bin/env python3
"""Normalize a saved official course-plan text. Never guesses unresolved codes."""
import argparse,datetime,hashlib,json,re
from pathlib import Path
URL='https://cse.uiu.ac.bd/ug-program/course-plan/'
def code(s):return re.sub(r'\s+','',s).upper()
def parse(text):
 rows={};bucket='';track='';term=None;sequence=False;equivalences=[]
 for line in text.splitlines():
  if line.startswith('Course Sequence'):sequence=True;continue
  if sequence:
   m=re.fullmatch(r'Trimester (\d+):?',line.strip())
   if m:term=int(m[1]);continue
  if not sequence and line.startswith('####'):
   title=line.lstrip('#').strip()
   if '(A)' in title:bucket='language'
   elif '(B)' in title:bucket='general-required'
   elif title.startswith('Optional'):bucket='general-elective'
   elif '(C)' in title:bucket='science'
   elif '(D)' in title:bucket='math'
   elif '(E)' in title:bucket='engineering'
   elif '(F)' in title:bucket='core'
   elif '(G)' in title:bucket='elective'
   elif 'Final Year Design Project' in title:bucket='fydp'
   if bucket=='elective' and re.match(r'[iv]+\.',title):track=title.split('.',1)[1].strip()
  cells=[x.strip() for x in line.split('|')]
  if len(cells)>=4 and cells[0].isdigit() and re.fullmatch(r'[A-Z]+\s+\d{4}\s*[ABC]?',cells[1]):
   c=code(cells[1]);credits=float(cells[3]);title=cells[2]
   if sequence:
    if c in rows:
     rows[c]['recommended_trimester']=term
     rows[c]['prerequisites']=re.findall(r'[A-Z]+\s+\d{4}\s*[ABC]?',cells[4]) if len(cells)>4 else []
     rows[c]['prerequisites']=[code(x) for x in rows[c]['prerequisites']]
   else:
    row=rows.setdefault(c,{'code':c,'display_code':cells[1],'title':title,'credits':credits,'bucket':bucket,'tracks':[],'prerequisites':[],'description_url':'https://cse.uiu.ac.bd/ug-program/course-description/'})
    if bucket=='elective' and track and track not in row['tracks']:row['tracks'].append(track)
  elif not sequence and len(cells)>=6 and re.fullmatch(r'[A-Z]+\s+\d{4}\s*[ABC]?',cells[0]) and re.fullmatch(r'[A-Z]+\s+\d{4}\s*[ABC]?',cells[3]):
   equivalences.append({'course':code(cells[0]),'equivalent':code(cells[3]),'source':URL})
 problems=[]
 for row in rows.values():
  for p in row['prerequisites']:
   if p not in rows:problems.append({'course':row['code'],'unknown_prerequisite':p,'resolution':'unresolved; do not infer substitution'})
 required=sum(r['credits'] for r in rows.values() if r['bucket'] not in ('elective','general-elective'))
 if required!=117:raise ValueError('Incomplete or inconsistent required catalogue: '+str(required)+' credits, expected 117 plus elective baskets of 24')
 for course,plan,description in [('CSE1115','CSE2215','CSE1111'),('CSE1116','CSE2216','CSE1112')]:
  problems.append({'course':course,'conflicting_prerequisites':{'course_plan':[plan],'course_description':[description]},'resolution':'unresolved; advisor/updated curriculum confirmation required'})
 problems.append({'course':'BIO3105','conflicting_credits':{'course_plan':3,'course_description':1},'resolution':'Use selected cohort course-plan requirement; description source is inconsistent and needs official confirmation'})
 return {'description_coverage':'Course description source links included; descriptions and prerequisites are not all independently reconciled with the course sequence','grade_policy_source':'https://www.uiu.ac.bd/academics/grading-performance-evaluation/','attendance_policy_source':'https://www.uiu.ac.bd/academics/academic-information-policies/','version':1,'institution':'United International University, Bangladesh','program':'BSCSE','effective_from':'Summer 2026','degree_credits':141,'minimum_cgpa':2.0,'minimum_fydp_grade':'C','baskets':{'general-elective':9,'elective':15},'specialization_minimum_courses':4,'courses':list(rows.values()),'equivalences':equivalences,'issues':problems,'source':{'url':URL,'retrieved_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sha256':hashlib.sha256(text.encode()).hexdigest(),'method':'indexed official page text; direct fetch unavailable','status':'source discrepancies require review'}}
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('source',type=Path);p.add_argument('output',type=Path);a=p.parse_args();value=parse(a.source.read_text().split('--------------------------------------------------------------------------------')[0]);a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n');print(len(value['courses']),'courses;',len(value['issues']),'unresolved prerequisites')
