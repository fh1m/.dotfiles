"""Bounded read-only projections across explicitly selected registered learning vaults."""
import hashlib
import json
import sqlite3
from pathlib import Path
from .scopes import locations, identity
from .views import today


def selected_roots(values):
    if not isinstance(values,list) or not 1 <= len(values) <= 16 or any(not isinstance(v,str) for v in values):
        raise ValueError('Select between one and sixteen registered learning vaults')
    registered=locations(include_missing=True)
    roots=sorted({Path(v).expanduser().resolve() for v in values},key=str)
    seen=set()
    for root in roots:
        if root not in registered:raise ValueError('Collection scope is not registered: '+str(root))
        if not root.is_dir():continue
        try:vault_id=identity(root)
        except (ValueError,OSError):
            if any((root/relative).is_file() for relative in ('System/System.json','94 Meta/System.json')):continue
            raise
        if not vault_id:raise ValueError('Collection scope requires a managed vault identity')
        if root.name in ('Downloads','Archives'):raise ValueError('This directory is outside the learning collection')
        if vault_id in seen:raise ValueError('Duplicate vault identity in collection; resolve replacement or fork first')
        seen.add(vault_id)
    return roots


def annotate(index,row):
    return dict(row,vault=str(index.root),vault_id=index.manifest['vault_id'],vault_name=index.root.name)


def project(request,get_index):
    roots=selected_roots(request.get('vaults'))
    signature=hashlib.sha256(json.dumps({'vaults':[str(r) for r in roots],'query':request.get('query',''),'kind':request.get('kind'),'resource_kinds':request.get('resource_kinds')},sort_keys=True).encode()).hexdigest()[:16]
    errors=[]
    if request['action']=='collection-today':
        resumes=[];actions=[];paths=[];count=0;generations={}
        for root in roots:
            try:
                if not root.is_dir():raise ValueError("Registered vault storage is unavailable")
                if not identity(root):raise ValueError("Managed vault identity is unavailable")
                index=get_index(root,True)
                context=request.get('context_id') if str(root)==request.get('context_vault') else None
                result=today(index,context,None,request.get('quiet',False))
                if result['continue']:resumes.append(annotate(index,result['continue']))
                actions.extend(annotate(index,row) for row in result['records'])
                paths.extend(annotate(index,row) for row in result['paths'])
                count+=result['record_count'];generations[str(root)]=index.generation
            except (ValueError,OSError,sqlite3.Error) as error:errors.append({'vault':str(root),'message':str(error)})
        resumes.sort(key=lambda row:row.get('last_worked') or '',reverse=True)
        actions.sort(key=lambda row:(row.get('priority',100),row['vault'],row['path']))
        return {'continue':resumes[0] if resumes else None,'continuations':resumes[:8],
                'records':actions[:5],'paths':paths[:8],'record_count':count,'generations':generations,
                'scope_errors':errors,'availability':'partial' if errors else 'ready',
                'empty_reason':'data-unavailable' if errors and not count else 'no-records' if not count else 'no-active-work' if not resumes and not actions else 'nothing-due' if not actions else None}
    cursor=request.get('cursor')
    indexes={};generations={};owners={}
    for root in roots:
        try:
            if not root.is_dir():raise ValueError("Registered vault storage is unavailable")
            if not identity(root):raise ValueError("Managed vault identity is unavailable")
            index=get_index(root,not cursor)
            indexes[str(root)]=index;generations[str(root)]=[index.cache_identity,index.generation]
            owners[str(root)]=index.manifest['vault_id']
        except (ValueError,OSError,sqlite3.Error) as error:
            errors.append({'vault':str(root),'message':str(error)})
    offsets={str(root):0 for root in roots}
    if cursor:
        try:position=json.loads(cursor)
        except (ValueError,TypeError):raise ValueError('Invalid collection cursor')
        if not isinstance(position,dict):raise ValueError('Invalid collection cursor')
        if position.get('signature')!=signature:raise ValueError('Collection scope changed; restart search')
        if position.get('generations')!=generations or position.get('owners')!=owners:
            raise ValueError('Learning collection changed; refresh search before loading more')
        offsets=position.get('offsets')
        if not isinstance(offsets,dict) or set(offsets)!={str(root) for root in roots} or any(type(n) is not int or n<0 for n in offsets.values()):
            raise ValueError('Invalid collection cursor')
    query=request.get('query','')
    if not isinstance(query,str):raise ValueError('Search query must be text')
    query=query.strip();candidates=[];pages={}
    for root,index in indexes.items():
        page=index.query(query,request.get('kind'),offsets[root],50,
                         resource_kinds=request.get('resource_kinds'),relevance=True)
        pages[root]=page
        for row in page['records']:
            # SQL's identity/alias tier is checked against this owning index only.
            alias=query.lower()
            import re
            if re.match(r'^(https?://(dx\.)?doi\.org/|doi:)',alias):alias='doi:'+re.sub(r'^(https?://(dx\.)?doi\.org/|doi:)','',alias)
            elif re.match(r'^10\.\d{4,9}/',alias):alias='doi:'+alias
            exact=query==row['id'] or bool(query and index.db.execute('SELECT 1 FROM aliases WHERE path=? AND alias=?',(row['path'],alias)).fetchone())
            # SQLite lower() folds ASCII only; match it for stable Unicode paging.
            title=row['title'].translate(str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'))
            rank=0 if exact else 1 if query and title==query.lower() else 2 if query and title.startswith(query.lower()) else 3
            candidates.append((rank,title,root,row['path'],annotate(index,row)))
    candidates.sort(key=lambda item:item[:4])
    records=[];size=0
    for *_,item in candidates:
        item_size=len(json.dumps(item).encode())
        if item_size>58*1024:raise ValueError('Summary cannot fit bounded response')
        if len(records)==50 or size+item_size>58*1024:break
        records.append(item);size+=item_size;offsets[item['vault']]+=1
    more=len(candidates)>len(records) or any(page['cursor'] is not None for page in pages.values())
    next_cursor=json.dumps({'offsets':offsets,'signature':signature,'generations':generations,'owners':owners},separators=(',',':')) if more else None
    return {'records':records,'cursor':next_cursor,'generations':generations,
            'scope_errors':errors,'availability':'partial' if errors else 'ready'}
