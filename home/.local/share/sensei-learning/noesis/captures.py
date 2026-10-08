"""Instant free-text capture with a recoverable publication receipt."""
from datetime import datetime,timezone
import json
import re
import uuid
from .persistence import lock,manifest_path,publish,render,contained,checksum
from .index import Index


def capture(root,text,kind='capture',agent=False,operation_id=None):
    if not isinstance(text,str) or not text.strip():raise ValueError('Capture text is empty')
    if kind not in ('capture','snippet','question'):raise ValueError('Unsupported capture kind')
    operation_id=operation_id or str(uuid.uuid4());uuid.UUID(operation_id)
    request_hash=checksum(json.dumps({'text':text,'kind':kind,'agent':agent},sort_keys=True))
    with lock(root):
        meta=json.loads(manifest_path(root).read_text())
        journal_path=contained(root,'.Noesis/Operations/'+operation_id+'.json')
        original=journal_path.read_text() if journal_path.exists() else None
        if original:
            journal=json.loads(original)
            if journal.get('request_hash')!=request_hash:raise ValueError('Operation ID reused with changed capture content')
            index=Index(root)
            try:
                health=index.reconcile()
                if health['errors']:raise ValueError('Could not verify previous capture: '+str(health['errors']))
                rows=list(index.db.execute("SELECT path FROM records WHERE json_extract(props,'$.operation_id')=?",(operation_id,)))
                if len(rows)==1:
                    if journal.get('status')!='committed':
                        journal['status']='committed';publish(journal_path,json.dumps(journal,indent=2),checksum(original))
                    return contained(root,rows[0][0])
                if rows or journal.get('status')=='committed':raise ValueError('Previous capture committed but is missing or duplicated; inspect recovery before retrying')
            finally:index.close()
        else:
            now=datetime.now(timezone.utc)
            inbox='Inbox' if meta.get('layout')=='network' else '90 Inbox'
            if agent:inbox+='/Agent Drops'
            journal={'operation_id':operation_id,'request_hash':request_hash,'status':'preparing','record_id':str(uuid.uuid4()),
                     'path':inbox+'/'+now.strftime('%Y%m%d-%H%M%S-%f')+'.md','timestamp':now.isoformat()}
            original=json.dumps(journal,indent=2);publish(journal_path,original)
        title=re.sub(r'^\s*#+\s*','',text.strip().splitlines()[0])[:160]
        record={'id':journal['record_id'],'noesis_schema':2,'type':kind,'title':title,'status':'inbox',
                'created':journal['timestamp'],'operation_id':operation_id,'request_hash':request_hash,
                'provenance':'agent-output-unverified' if agent else 'learner-capture'}
        path=contained(root,journal['path']);publish(path,render(record,'\n'+text+'\n'))
        journal['status']='committed';publish(journal_path,json.dumps(journal,indent=2),checksum(original))
        return path
