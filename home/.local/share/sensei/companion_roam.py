"""Companion leases are independent of cursor/input ownership."""
import time

def grant(record, output, token, ttl=40, now=None):
    now=time.time() if now is None else now
    if not isinstance(token,int) or token<=record.get('token',0):raise ValueError('Stale companion journey')
    if not isinstance(output,str) or len(output)>80 or ttl<0 or ttl>45:raise ValueError('Invalid companion lease')
    return {'schema':1,'token':token,'output':output,'expires':now+ttl,'managed':True}

def valid(record,now=None):
    now=time.time() if now is None else now
    return record.get('schema')==1 and record.get('expires',0)>now and bool(record.get('output'))


def memory(record):
    """Only repertoire IDs and a monotonic sequence cross a companion lease."""
    if not isinstance(record,dict):return {'turn':0,'recent':[]}
    turn=record.get('turn',0);recent=record.get('recent',[])
    if type(turn) is not int or not 0<=turn<2**53:turn=0
    if not isinstance(recent,list):recent=[]
    return {'turn':turn,'recent':[x for x in recent[-40:] if type(x) is int and 0<=x<100000]}


def newer_memory(a,b):
    a,b=memory(a),memory(b)
    return b if b['turn']>a['turn'] else a


def engineering_events(events,now=None):
    """Cross-host curated receipts only: no logs, titles, code, commands or arbitrary actions."""
    import re,time
    now=time.time() if now is None else now
    kinds={'project.launch','job.completed','experiment.completed','hardware.disconnected','hardware.returned'}
    out=[]
    for event in events[-16:] if isinstance(events,list) else []:
        if not isinstance(event,dict) or event.get('kind') not in kinds:continue
        try:
            import uuid
            identity=str(uuid.UUID(event['id']));at=float(event['at'])
        except (KeyError,ValueError,TypeError):continue
        if not 0<=now-at<120 or event.get('host') not in ('arete','homie'):continue
        raw=event.get('data',{});data={}
        if not isinstance(raw,dict):continue
        if raw.get('outcome') in ('passed','succeeded','failed','interrupted'):data['outcome']=raw['outcome']
        if isinstance(raw.get('job'),str) and re.fullmatch(r'[A-Za-z0-9-]{1,60}',raw['job']):data['job']=raw['job']
        if event['kind'].startswith('hardware.') and isinstance(raw.get('label'),str):data['label']=raw['label'][:60]
        out.append(dict(id=identity,at=at,host=event['host'],kind=event['kind'],data=data))
    return out[-8:]


def engineering_acks(values):
    import uuid
    out=[]
    for value in values[-256:] if isinstance(values,list) else []:
        try:identity=str(uuid.UUID(str(value)))
        except (ValueError,TypeError):continue
        if identity not in out:out.append(identity)
    return out[-128:]
