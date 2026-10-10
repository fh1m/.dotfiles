"""Display projections never rename files or change learner-authored text."""
from pathlib import PurePosixPath
from html import escape
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
    """A bounded native reading projection, never an Obsidian renderer.

    Only generated inline formatting; no source HTML, scripts, images or requests. Full source
    remains unchanged and opens in its specialist application.
    """
    blocks=[];paragraph=[];code=[];fenced=False;features=set();language='';equation=False
    def inline(text):
        # Only generated formatting reaches Qt RichText. Source HTML, images and
        # link destinations are never interpreted or loaded by this projection.
        text=re.sub(r'\$([^$]+)\$',lambda match:'mathematical expression' if re.search(r'[\\{}]',match[1]) else match[1],text)
        parts=re.split(r'(`[^`\n]+`)',text)
        rendered=[]
        for part in parts:
            if part.startswith('`') and part.endswith('`'):
                rendered.append('<code>'+escape(part[1:-1])+'</code>');continue
            part=escape(part)
            part=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',part)
            part=re.sub(r'__(.+?)__',r'<b>\1</b>',part)
            part=re.sub(r'(?<!\*)\*(\S(?:[^*\n]*?\S)?)\*(?!\*)',r'<i>\1</i>',part)
            part=re.sub(r'(?<!\w)_([^_\n]+)_(?!\w)',r'<i>\1</i>',part)
            part=re.sub(r'~~(.+?)~~',r'<s>\1</s>',part)
            rendered.append(part)
        return ''.join(rendered).replace('\n','<br>')
    def formatted(kind,text,**extra):
        return dict(kind=kind,text=text,html=inline(text),**extra)
    def flush():
        if paragraph:
            rows=list(paragraph)
            if len(rows)>=2 and '|' in rows[0] and re.fullmatch(r'\s*\|?\s*:?-+:?\s*(?:\|\s*:?-+:?\s*)+\|?\s*',rows[1]):
                cells=lambda row:[value.strip() for value in row.strip().strip('|').split('|')]
                headings=cells(rows[0]);data=[cells(row) for row in rows[2:]]
                if len(headings)<=8 and len(data)<=20:
                    rows=[(row+['']*len(headings))[:len(headings)] for row in data]
                    blocks.append(dict(kind='table',text='Table',columns=headings,rows=rows,columns_html=[inline(cell) for cell in headings],rows_html=[[inline(cell) for cell in row] for row in rows]))
                else:
                    features.add('large tables');blocks.append(dict(kind='caption',text='Large table · open the complete note'))
            elif all(re.match(r'^\s*(?:[-+*]|\d+[.)])\s+',row) for row in rows):
                items=[];rendered=[]
                for row in rows:
                    match=re.match(r'^(\s*)([-+*]|\d+[.)])\s+(.*)$',row)
                    item=match[3];task=re.match(r'^\[([ xX])\]\s*(.*)',item)
                    prefix=('☑ ' if task[1].lower()=='x' else '☐ ') if task else (match[2]+' ' if match[2][0].isdigit() else '• ')
                    item=task[2] if task else item
                    items.append(match[1]+prefix+item)
                    rendered.append('&#160;'*min(24,len(match[1]))+escape(prefix)+inline(item))
                blocks.append(dict(kind='list',text='\n'.join(items),html='<br>'.join(rendered)))
            elif all(row.lstrip().startswith('>') for row in rows):
                blocks.append(formatted('quote','\n'.join(re.sub(r'^\s*>\s?', '',row) for row in rows)))
            else:
                blocks.append(formatted('body','\n'.join(rows)))
            paragraph.clear()
    for line in body[:32000].splitlines()[:500]:
        if line.startswith('```'):
            flush()
            if fenced:
                if language.lower() in ('mermaid','math','latex'):
                    features.add('diagrams' if language.lower()=='mermaid' else 'mathematics')
                    blocks.append({'kind':'caption','text':('Diagram' if language.lower()=='mermaid' else 'Equation')+' · open the complete note'})
                else:blocks.append({'kind':'code','text':'\n'.join(code),'language':language[:40]})
                code=[]
            else:language=line[3:].strip()
            fenced=not fenced
            continue
        if fenced:code.append(line);continue
        if line.strip().startswith('$$'):
            flush();features.add('mathematics')
            if not equation:blocks.append({'kind':'caption','text':'Equation · open the complete derivation in Obsidian'})
            equation=not equation if line.strip()=='$$' else False
            continue
        if equation:continue
        if re.match(r'^\s*<(?:script|style|iframe|img|div|table|svg|video|audio|!--)\b',line,re.I):
            flush();features.add('HTML content');blocks.append({'kind':'caption','text':line,'display_text':'HTML content · open the complete note'});continue
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
            blocks.append(formatted('heading',text,level=len(heading[1])));continue
        if re.fullmatch(r'\s*(?:---+|\*\*\*+|___+)\s*',line):flush();continue
        if not line.strip():flush()
        else:
            list_line=bool(re.match(r'^\s*(?:[-+*]|\d+[.)])\s+',line))
            quote_line=line.lstrip().startswith('>')
            if paragraph:
                was_list=bool(re.match(r'^\s*(?:[-+*]|\d+[.)])\s+',paragraph[0]))
                was_quote=paragraph[0].lstrip().startswith('>')
                if was_list and not list_line and line.startswith('  '):
                    paragraph[-1]+=' '+line.strip();continue
                if list_line!=was_list or quote_line!=was_quote:flush()
            paragraph.append(line)
    flush()
    if code:blocks.append({'kind':'code','text':'\n'.join(code)})
    return {'blocks':blocks[:100],'specialist_features':sorted(features),
            'truncated':len(body)>32000 or len(body.splitlines())>500 or len(blocks)>100}
