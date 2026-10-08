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
    position={'scope':0,'offset':0,'signature':signature}
    if cursor:
        try:position=json.loads(cursor)
        except (ValueError,TypeError):raise ValueError('Invalid collection cursor')
        if position.get('signature')!=signature:raise ValueError('Collection scope changed; restart search')
        if type(position.get('scope')) is not int or type(position.get('offset')) is not int or not 0<=position['scope']<len(roots) or position['offset']<0:raise ValueError('Invalid collection cursor')
    records=[];size=0;scope=position['scope'];offset=position['offset'];next_cursor=None
    while scope<len(roots) and len(records)<50:
        try:
            if not roots[scope].is_dir():raise ValueError("Registered vault storage is unavailable")
            if not identity(roots[scope]):raise ValueError("Managed vault identity is unavailable")
            index=get_index(roots[scope],not cursor)
            page=index.query(request.get('query',''),request.get('kind'),offset,50-len(records),resource_kinds=request.get('resource_kinds'))
            consumed=0
            for row in page['records']:
                item=annotate(index,row);item_size=len(json.dumps(item).encode())
                if item_size>58*1024:raise ValueError('Summary cannot fit bounded response')
                if size+item_size>58*1024:break
                records.append(item);size+=item_size;consumed+=1
            if consumed<len(page['records']):offset+=consumed;break
            if page['cursor'] is not None:offset=page['cursor'];break
        except (ValueError,OSError,sqlite3.Error) as error:errors.append({'vault':str(roots[scope]),'message':str(error)})
        scope+=1;offset=0
    if scope<len(roots):next_cursor=json.dumps({'scope':scope,'offset':offset,'signature':signature},separators=(',',':'))
    return {'records':records,'cursor':next_cursor,'scope_errors':errors,'availability':'partial' if errors else 'ready'}
