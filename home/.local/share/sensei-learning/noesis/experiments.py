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
                    if file.suffix.lower()=='.png' and item['size']<=25*1024*1024:
                        with file.open('rb') as stream:header=stream.read(24)
                        if len(header)==24 and header[:8]==b'\x89PNG\r\n\x1a\n' and header[12:16]==b'IHDR':
                            width,height=struct.unpack('>II',header[16:24])
                            if 0<width<=4096 and 0<height<=4096 and width*height<=8*1024*1024:
                                item['figure_url']=file.resolve().as_uri()
            artifacts.append(item)
        except (ValueError,OSError,TypeError) as error:errors.append(str(error))
    config=props.get('configuration') or {}
    configuration=[{'name':str(key)[:80],'value':(value if isinstance(value,str) else json.dumps(value,ensure_ascii=False))[:256]} for key,value in list(config.items())[:16]] if isinstance(config,dict) else [{'name':'Configuration','value':str(config)[:1024]}]
    return {'kind':'project' if props.get('type')=='project' else 'experiment',
            'hypothesis':props.get('hypothesis'),'code':props.get('code_snapshot'),
            'configuration':configuration,'latest_comparison':json.loads(latest[0]) if latest else None,
            'comparison_count':comparison_count,'artifacts':artifacts,'artifacts_truncated':len(rows)>20,
            'artifact_errors':errors,'summary':'Execution, reported observation and supported hypothesis are separate'}
