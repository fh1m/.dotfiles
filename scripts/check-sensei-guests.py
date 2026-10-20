#!/usr/bin/env python3
"""Validate shipped guest content/art and optionally check excerpts against a local public-source corpus."""
import argparse,collections,hashlib,json,re,unicodedata
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'home/.local/share/sensei-companion/guests'
EXPECTED={'feynman','hotz','carmack','karpathy','keller','lattner','graham','urban','west','rubin'}
def normalized(s):return re.sub(r'[^a-z0-9]+',' ',unicodedata.normalize('NFKD',s).lower()).strip()
def check(corpus=None):
 d=json.loads((DATA/'catalog.json').read_text());assert d['schema']==1
 assert {g['id'] for g in d['guests']}==EXPECTED
 used=set();words=collections.Counter();checks=[];stories=0
 for g in d['guests']:
  assert len(g['quotes'])>=10,(g['id'],'fewer than ten excerpts')
  assert g['story'] and g['role'] and g['storySource'] in d['sources']
  with Image.open(DATA/g['atlas']) as im:
   assert im.mode=='RGBA' and im.width%2==im.height%2==0 and min(im.size)>=1024,g['id']
   assert im.getchannel('A').getextrema()==(0,255),g['id']
   for y in range(2):
    for x in range(2):
     assert im.crop((x*im.width//2,y*im.height//2,(x+1)*im.width//2,(y+1)*im.height//2)).getchannel('A').getbbox(),g['id']
  topics=g.get('topics',[])
  assert len(topics)>=10,g['id']
  for topic in topics:
   assert topic['id'] not in used;used.add(topic['id'])
   assert topic['source'] in d['sources'] and topic['question'].endswith('?')
   assert topic['title'] and topic['story'] and topic['task'];stories+=1
  for q in g['quotes']:

   assert q['id'] not in used;used.add(q['id'])
   assert len(q['text'].split())>=3,(q['id'],'empty slogan fragment')
   assert q['question'].endswith('?') and q['context'] and q['excerpt'] is True
   source=d['sources'][q['source']];assert source['url'].startswith(('https://','http://number-none.com/'))
   words[q['source']]+=len(q['text'].split())
   if corpus:
    p=Path(corpus)/(q['source']+'.txt');raw=p.read_text();needle=normalized(q['text']);offset=normalized(raw).find(needle)
    assert offset>=0,(q['id'],'not found in inspected source')
    checks.append({'id':q['id'],'source':q['source'],'sourceSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'excerptSha256':hashlib.sha256(q['text'].encode()).hexdigest(),'normalizedOffset':offset})
 for name in ['zondo-listener-v1.png','zondo-listener-side-v1.png']:
  with Image.open(DATA/name) as im:
   assert im.mode=='RGBA' and min(im.size)>=1024 and im.width%2==im.height%2==0,name
   assert im.getchannel('A').getextrema()==(0,255),name
   for y in range(2):
    for x in range(2):assert im.crop((x*im.width//2,y*im.height//2,(x+1)*im.width//2,(y+1)*im.height//2)).getchannel('A').getbbox(),name
 assert max(words.values())<=25,dict(words)
 return {'guests':len(d['guests']),'quotations':sum(len(g['quotes']) for g in d['guests']),'curatedStories':stories,'originalWorkshopVariants':stories*9,'sources':len(d['sources']),'excerptSources':len(words),'maxQuotedWordsPerSource':max(words.values()),'sourceMatches':checks}
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--corpus',type=Path);p.add_argument('--write-audit',type=Path);a=p.parse_args();r=check(a.corpus)
 if a.write_audit:
  assert a.corpus,'--write-audit requires --corpus';a.write_audit.write_text(json.dumps(r,indent=2)+'\n')
 print(json.dumps({k:v for k,v in r.items() if k!='sourceMatches'}))
if __name__=='__main__':main()
