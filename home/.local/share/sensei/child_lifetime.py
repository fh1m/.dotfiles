"""Bind owned long-lived CLI watchers to their launching UI process."""
import ctypes,os,signal

def bind_parent():
 parent=os.getppid()
 def terminate(*_):raise SystemExit(0)
 signal.signal(signal.SIGTERM,terminate)
 if ctypes.CDLL(None,use_errno=True).prctl(1,signal.SIGTERM,0,0,0)!=0:
  raise OSError(ctypes.get_errno(),'Cannot bind watcher lifetime')
 if parent==1 or os.getppid()!=parent:raise SystemExit(0)
