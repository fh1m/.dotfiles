#!/usr/bin/env python3
"""Owned GTK receiver for explicit tests; observes only its own window events."""
import argparse,json,os,pathlib

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--owned-fixture',action='store_true');a=p.parse_args()
    if not a.owned_fixture:p.error('Explicit owned-fixture mode required')
    import gi
    gi.require_version('Gtk','3.0')
    from gi.repository import Gtk,Gdk
    root=pathlib.Path.home()/'.local/state/homie-control/input-test';root.mkdir(exist_ok=True)
    output=root/'events.json';counts={'keys':{},'held':[],'buttons':0,'scrolls':0,'events':[]}
    allowed={'d','e','n','a','Control_L','Alt_L','Escape','Shift_L'}
    held=set()
    def save():
        temp=output.with_suffix('.next');temp.write_text(json.dumps(counts));temp.chmod(0o600);temp.replace(output)
    def key(win,event,down):
        name=Gdk.keyval_name(event.keyval)
        if name in allowed:counts['events'].append({'key':name,'down':down,'mods':int(event.state)})
        if name in allowed:
            if down:counts['keys'][name]=counts['keys'].get(name,0)+1;held.add(name)
            else:held.discard(name)
        counts['held']=sorted(held);save();return False
    def button(win,event):counts['buttons']+=1;save();return False
    def scroll(win,event):counts['scrolls']+=1;save();return False
    win=Gtk.Window(title='Den input harness');win.set_default_size(900,850)
    box=Gtk.EventBox();box.set_can_focus(True)
    box.add_events(Gdk.EventMask.BUTTON_PRESS_MASK|Gdk.EventMask.SCROLL_MASK|Gdk.EventMask.SMOOTH_SCROLL_MASK)
    box.connect('button-press-event',button);box.connect('scroll-event',scroll)
    win.connect('key-press-event',lambda w,e:key(w,e,True));win.connect('key-release-event',lambda w,e:key(w,e,False))
    box.add(Gtk.Label(label='DIGITAL DEN / INPUT CHECK\n\nOwned test window. No user applications receive test input.'))
    win.add(box);win.connect('destroy',Gtk.main_quit);save();win.show_all();box.grab_focus();Gtk.main()
if __name__=='__main__':main()
