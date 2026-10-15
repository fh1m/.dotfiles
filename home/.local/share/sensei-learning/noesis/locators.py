"""Medium-specific resume locations without equating consumption with assessment."""
import math
import re


def normalize(locator):
    if not isinstance(locator,dict) or set(locator)-{'kind','value','seconds'}:raise ValueError('Locator must contain kind and value')
    kind,value=locator.get('kind'),locator.get('value')
    if kind not in ('page','section','exercise','timestamp'):raise ValueError('Unsupported locator kind')
    if kind=='page':
        if isinstance(value,str) and value.isdecimal():value=int(value)
        if type(value) is not int or value<1:raise ValueError('Page must be a positive integer')
        return {'kind':kind,'value':value},'page '+str(value)
    if kind=='timestamp':
        if type(value) in (int,float):
            seconds=value
        elif isinstance(value,str):
            match=re.fullmatch(r'(?:(\d+):)?([0-5]?\d):([0-5]\d)',value.strip())
            if not match:raise ValueError('Use timestamp MM:SS or HH:MM:SS')
            hours,minutes,second=match.groups();seconds=int(hours or 0)*3600+int(minutes)*60+int(second)
        else:raise ValueError('Timestamp must be seconds or MM:SS / HH:MM:SS')
        if seconds<0 or not math.isfinite(seconds):raise ValueError('Timestamp must be finite and nonnegative')
        return {'kind':kind,'value':value,'seconds':seconds},'timestamp '+str(value)
    if not isinstance(value,str) or not value.strip() or len(value)>256:raise ValueError('Section or exercise needs a short label')
    return {'kind':kind,'value':value.strip()},kind+' '+value.strip()
