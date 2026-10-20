#!/usr/bin/env python3
"""Compile the maintained, human-readable topic deck without changing real excerpts."""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'home/.local/share/sensei-companion/guests'
def build():
 groups={}
 for number,line in enumerate((DATA/'topics.tsv').read_text().splitlines(),1):
  if not line.strip() or line.startswith('#'):continue
  guest,title,source,story,task,question=line.split('|')
  assert question.endswith('?'),number
  groups.setdefault(guest,[]).append({'id':f'{guest}-topic-{len(groups.get(guest,[]))+1:02d}','title':title,'source':source,'story':story,'task':task,'question':question})
 return groups
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check',action='store_true');a=p.parse_args()
 path=DATA/'catalog.json';d=json.loads(path.read_text());groups=build()
 assert set(groups)=={g['id'] for g in d['guests']}
 for guest in d['guests']:
  topics=groups[guest['id']];assert len(topics)>=10
  assert all(t['source'] in d['sources'] for t in topics)
  if a.check:assert guest.get('topics')==topics,guest['id']
  else:guest['topics']=topics
 if not a.check:path.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 print(f"{sum(len(v) for v in groups.values())} curated topic stories; {sum(len(v) for v in groups.values())*9} original workshop variants; {sum(len(g['quotes']) for g in d['guests'])} real excerpts retained")
if __name__=='__main__':main()
