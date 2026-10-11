#!/usr/bin/env python3
"""Build a pink XCursor variant of the installed Adwaita theme.

Preserves native hotspots, animation frames, aliases, alpha and dark outlines.
Source artwork: GNOME Adwaita, CC-BY-SA 3.0 (see index.theme attribution).
"""
import argparse
from pathlib import Path
import shutil
import struct


def recolor(data):
    data=bytearray(data)
    if data[:4]!=b'Xcur':raise ValueError('Invalid XCursor')
    _,_,_,count=struct.unpack_from('<4I',data)
    for i in range(count):
        kind,_,offset=struct.unpack_from('<3I',data,16+12*i)
        if kind!=0xfffd0002:continue
        header,_,_,_,width,height,*_=struct.unpack_from('<9I',data,offset)
        if width*height>1024*1024:raise ValueError('Cursor size exceeds bound')
        for pos in range(offset+header,offset+header+width*height*4,4):
            pixel=struct.unpack_from('<I',data,pos)[0]
            a=(pixel>>24)&255;r=(pixel>>16)&255;g=(pixel>>8)&255;b=pixel&255
            if a and max(r,g,b)>a*.45:
                # XCursor pixels are premultiplied ARGB.
                shade=max(r,g,b)/255
                r,g,b=(round(c*shade) for c in (242,61,112))
                struct.pack_into('<I',data,pos,(a<<24)|(r<<16)|(g<<8)|b)
    return data


def build(source,destination):
    destination.mkdir(parents=True,exist_ok=True)
    cursors=destination/'cursors';cursors.mkdir(exist_ok=True)
    for path in source.iterdir():
        target=cursors/path.name
        if path.is_symlink():
            if target.is_symlink():target.unlink()
            target.symlink_to(path.readlink())
        elif path.is_file():target.write_bytes(recolor(path.read_bytes()))
    (destination/'index.theme').write_text('[Icon Theme]\nName=Sensei Signal\nComment=Pink variant of GNOME Adwaita cursors; CC-BY-SA 3.0; https://gitlab.gnome.org/GNOME/adwaita-icon-theme\nInherits=Adwaita\n')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=Path('/usr/share/icons/Adwaita/cursors'));p.add_argument('--dest',type=Path,default=Path.home()/'.local/share/icons/Sensei-Signal');a=p.parse_args();build(a.source,a.dest)
