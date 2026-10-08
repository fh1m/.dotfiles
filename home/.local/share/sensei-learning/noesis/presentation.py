"""Display projections never rename files or change learner-authored text."""
from pathlib import PurePosixPath
import re


def display_title(props, path):
    title=props.get('title') or props.get('imported_title')
    # Legacy titles sometimes contain the complete storage path.
    if not isinstance(title,str) or not title.strip() or title == path or title.endswith('.md') and '/' in title:
        title=PurePosixPath(path).stem
    title=title.strip()
    kind=props.get('type')
    prefixes={'prerequisite':r'^Prerequisite\s*[-–:]\s*','stage':r'^Stage\s*\d+\s*[-–:]\s*'}
    if kind in prefixes:title=re.sub(prefixes[kind],'',title,flags=re.I)
    return title or 'Untitled'


def preview(body,title=''):
    """A bounded plain-text orientation view, never an Obsidian renderer.

    No HTML interpretation, scripts, image loading or remote requests. Full source
    remains unchanged and opens in its specialist application.
    """
    blocks=[];paragraph=[];code=[];fenced=False;features=set()
    def flush():
        if paragraph:
            blocks.append({'kind':'body','text':'\n'.join(paragraph)})
            paragraph.clear()
    for line in body[:32000].splitlines()[:500]:
        if line.startswith('```'):
            flush()
            if fenced:blocks.append({'kind':'code','text':'\n'.join(code)});code=[]
            fenced=not fenced
            continue
        if fenced:code.append(line);continue
        if re.search(r'!\[|!\[\[',line):
            features.add('images or embeds');flush();blocks.append({'kind':'caption','text':'Embedded material · open the original document'});continue
        if '$' in line:features.add('mathematics')
        if re.search(r'\[\[.*?\]\]',line):
            features.add('Obsidian links')
            line=re.sub(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]',lambda m:m[2] or m[1].split('/')[-1],line)
        # Link labels remain readable; specialist application owns navigation.
        line=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'\1',line)
        heading=re.match(r'^(#{1,6})\s+(.+)$',line)
        if heading:
            flush();text=heading[2]
            if len(heading[1])==1 and text.strip()==title.strip():continue
            blocks.append({'kind':'heading','level':len(heading[1]),'text':text});continue
        if not line.strip():flush()
        else:paragraph.append(line)
    flush()
    if code:blocks.append({'kind':'code','text':'\n'.join(code)})
    return {'blocks':blocks[:100],'specialist_features':sorted(features),
            'truncated':len(body)>32000 or len(body.splitlines())>500 or len(blocks)>100}
