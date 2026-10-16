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
