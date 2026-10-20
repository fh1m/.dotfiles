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
    kinds={'project.launch','job.submitted','job.completed','experiment.completed','hardware.disconnected','hardware.returned','hardware.ambiguous'}
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
        if isinstance(raw.get('failureKey'),str) and re.fullmatch('[a-f0-9]{64}',raw['failureKey']):data['failureKey']=raw['failureKey']
        if type(raw.get('repeatFailures')) is int and 0<=raw['repeatFailures']<=128:data['repeatFailures']=raw['repeatFailures']
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


def music_line(record, now=None):
    """Only a fresh current-line lyric receipt travels with Zondo; no media URLs."""
    if not isinstance(record,dict):return {}
    now=time.time()*1000 if now is None else now
    at=record.get('at')
    if type(at) not in (int,float) or not 0<=now-at<=30000 or record.get('playing') is not True:return {}
    raw=record.get('line','')
    if not isinstance(raw,str):return {}
    line=raw.strip()[:320]
    until=record.get('until')
    if type(until) in (int,float) and not now<until<=at+30000:return {}
    out={'at':at,'playing':True,'line':line} if line else {}
    if out and type(until) in (int,float):out['until']=until
    return out


def notification_receipt(record,host,now=None):
    """Bounded plain notification projection, kept only within the private Den."""
    import re
    if host not in ('arete','homie') or not isinstance(record,dict):return {}
    now=time.time()*1000 if now is None else now
    unread=record.get('unread',0)
    if type(unread) is not int:unread=0
    out={'host':host,'unread':max(0,min(100,unread)),'dnd':record.get('dnd') is True,'entries':[]}
    for row in record.get('entries',[])[:12] if isinstance(record.get('entries'),list) else []:
        if not isinstance(row,dict):continue
        at=row.get('at');identity=row.get('id','')
        if type(at) not in (int,float) or not 0<=now-at<86400000 or not isinstance(identity,str) or not re.fullmatch(host+r':\d+:\d+',identity):continue
        item={'id':identity,'at':at,'host':host,'phone':row.get('phone') is True}
        for key,size in [('app',60),('summary',120),('body',240)]:
            item[key]=str(row.get(key,'')).replace('\x00','')[:size]
        out['entries'].append(item)
    return out


def notification_acks(values):
    import re
    if not isinstance(values,list):return []
    return list(dict.fromkeys(x for x in values[-256:] if isinstance(x,str) and re.fullmatch(r'(arete|homie):\d+:\d+',x)))[-128:]
