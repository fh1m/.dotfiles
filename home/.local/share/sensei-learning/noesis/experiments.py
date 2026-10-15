"""Structured experiment evidence; bounded local figures, no code execution or fetches."""
import json,struct
from pathlib import Path
from .index import local_relationship
from .persistence import contained


def context(index,record):
    props=record['props'];identity=props['id'];owner=index.manifest['vault_id']
    latest=index.db.execute("SELECT props FROM activities WHERE target=? AND json_extract(props,'$.event')='comparison' ORDER BY timestamp DESC,path DESC LIMIT 1",(identity,)).fetchone()
    comparison_count=index.db.execute("SELECT count(*) FROM activities WHERE target=? AND json_extract(props,'$.event')='comparison'",(identity,)).fetchone()[0]
    artifacts=[];errors=[]
    rows=index.db.execute("SELECT child.id FROM relationships r JOIN records child ON child.id=r.target WHERE r.source=? AND child.kind='artifact' AND r.relation IN ('contains','produces','references') AND "+local_relationship('r')+" ORDER BY child.path LIMIT 21",(identity,owner,owner)).fetchall()
    if props.get('type') == 'artifact': rows=[(identity,)]+rows
    for artifact_id, in rows[:20]:
        try:
            artifact=index.record(artifact_id,include_body=False,include_attempt=False)
            location=artifact['props'].get('location') or artifact['props'].get('local_file')
            item={'id':artifact_id,'path':artifact['path'],'title':artifact['display_title'],
                  'type':'artifact','vault':str(index.root),'vault_id':owner,'location':location,
                  'availability':'artifact unavailable','figure_url':None}
            if location:
                file=Path(location).expanduser()
                if not file.is_absolute():file=contained(index.root,location)
                if file.is_file():
                    item.update(availability='available',size=file.stat().st_size)
                    if artifact['props'].get('artifact_kind') == 'drawing':
                        candidate=file.with_suffix('.png') if file.suffix=='.canvas' else file.with_name(file.name.replace('.excalidraw.md','.excalidraw.png'))
                        if candidate.is_file():
                            item['preview_status']='export is current' if candidate.stat().st_mtime_ns>=file.stat().st_mtime_ns else 'export may be stale; reopen drawing'
                            file=candidate
                            item['size']=file.stat().st_size
                        else:item['preview_status']='No exported preview; open editable drawing in Obsidian'
                    if file.suffix.lower()=='.png' and item['size']<=25*1024*1024:
                        with file.open('rb') as stream:header=stream.read(24)
                        if len(header)==24 and header[:8]==b'\x89PNG\r\n\x1a\n' and header[12:16]==b'IHDR':
                            width,height=struct.unpack('>II',header[16:24])
                            if 0<width<=4096 and 0<height<=4096 and width*height<=8*1024*1024:
                                item['figure_url']=file.resolve().as_uri()
            artifacts.append(item)
        except (ValueError,OSError,TypeError) as error:errors.append(str(error))
    unfinished=[];unfinished_scan_truncated=False
    execution_folder=index.root/'.Noesis/Executions'
    if props.get('scratch_directory') and execution_folder.is_dir():
        candidates=sorted(execution_folder.glob('*.json'),key=lambda p:p.stat().st_mtime_ns,reverse=True)
        unfinished_scan_truncated=len(candidates)>200
        candidates=candidates[:200]
        for candidate in candidates:
            try:
                if candidate.stat().st_size>128*1024:continue
                execution=json.loads(candidate.read_text())
                if execution.get('record_id')==identity and execution.get('status')=='started':
                    unfinished.append({'id':candidate.stem,'started_at':execution.get('started_at'),'message':'Capture has no completion receipt; it may still be running. Inspect the terminal and existing outputs before starting another run.'})
            except (ValueError,OSError,TypeError):continue
    output_preview='';error_preview='';output_truncated=False
    latest_comparison=json.loads(latest[0]) if latest else None
    if props.get('scratch_directory') and latest_comparison and latest_comparison.get('operation_id'):
        import uuid
        try:
            operation=str(uuid.UUID(latest_comparison['operation_id']))
            folder=contained(index.root,props['scratch_directory']+'/runs/'+operation)
            for name,key in [('stdout.txt','output'),('stderr.txt','error')]:
                path=folder/name
                if path.is_file():
                    with path.open('rb') as stream:value=stream.read(16001)
                    text=value[:16000].decode('utf-8',errors='replace');output_truncated=output_truncated or len(value)>16000
                    if key=='output':output_preview=text
                    else:error_preview=text
        except (ValueError,OSError):pass
    config=props.get('configuration') or {}
    configuration=[{'name':str(key)[:80],'value':(value if isinstance(value,str) else json.dumps(value,ensure_ascii=False))[:256]} for key,value in list(config.items())[:16]] if isinstance(config,dict) else [{'name':'Configuration','value':str(config)[:1024]}]
    return {'kind':'project' if props.get('type')=='project' else 'experiment',
            'hypothesis':props.get('hypothesis'),'code':props.get('code_snapshot'),'unfinished_executions':unfinished,'unfinished_scan_truncated':unfinished_scan_truncated,
            'configuration':configuration,'latest_comparison':latest_comparison,'output_preview':output_preview,'error_preview':error_preview,'output_truncated':output_truncated,
            'comparison_count':comparison_count,'artifacts':artifacts,'artifacts_truncated':len(rows)>20,
            'artifact_errors':errors,'summary':'Execution, reported observation and supported hypothesis are separate'}
