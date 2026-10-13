#!/usr/bin/env python3
"""Manual integration check using an isolated tmux socket and attached PTY."""
import os,pty,subprocess,time,tty,tempfile, pathlib
s='sensei-key-test-'+str(os.getpid());tmp=pathlib.Path(tempfile.mkdtemp());reader=tmp/'reader.py';result=tmp/'bytes'
reader.write_text('import os,tty,sys\ntty.setraw(0)\nos.write(1,b"\\x1b[>4;2mREADY")\nf=open(sys.argv[1],"ab",buffering=0)\nwhile True:\n b=os.read(0,1024)\n f.write(b)\n')
def tm(*a):return subprocess.check_output(['tmux','-L',s,*a],text=True).strip()
try:
 tm('-f',str(pathlib.Path(__file__).resolve().parents[1] / 'home/.tmux.conf'),'new-session','-d','-s','test','-x','100','-y','30',f'python3 {reader} {result}')
 master,slave=pty.openpty();tty.setraw(master)
 proc=subprocess.Popen(['tmux','-L',s,'attach','-t','test'],stdin=slave,stdout=slave,stderr=slave,env={**os.environ,'TERM':'alacritty'})
 time.sleep(.5)
 keys=b'\x1b[1;2D\x1b[1;2C\x1b[1;3D\x1b[Z\x1b[27;2;13~'
 os.write(master,keys);time.sleep(.4)
 received=result.read_bytes();assert received==keys.replace(b'\x1b[Z',b'\x1b[27;2;9~'),(received,keys)
 print('PASS real attached tmux input: Shift arrows, Alt+Left, Shift+Tab, Shift+Enter forwarded (Shift+Tab normalized to requested extended-key protocol)')
 proc.terminate();proc.wait(timeout=3);os.close(master);os.close(slave)
 tm('new-window','-d','-n','history',"python3 -c 'print(\"\\n\".join(\"row-%d\" % n for n in range(2500)))'; sleep 10")
 time.sleep(.3)
 pane=tm('display-message','-p','-t','test:history','#{pane_id}')
 count=int(tm('display-message','-p','-t',pane,'#{history_size}'));assert count>2400,count
 tm('copy-mode','-u','-t',pane);assert tm('display-message','-p','-t',pane,'#{pane_in_mode}')=='1'
 history=tm('capture-pane','-p','-S','-','-t',pane);assert 'row-0' in history and 'row-2499' in history
 tm('send-keys','-X','-t',pane,'cancel');assert tm('display-message','-p','-t',pane,'#{pane_in_mode}')=='0'
 print('PASS 2,500-line history retained, copy-mode entered/exited without touching application')
finally:
 subprocess.run(['tmux','-L',s,'kill-server'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
