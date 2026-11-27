import unittest,tempfile,subprocess,os,json,sqlite3
from pathlib import Path
SCRIPT=Path(__file__).resolve().parents[1]/'home/.local/bin/sensei-calendar'
class Revisions(unittest.TestCase):
 def test_revision_and_cancel_preserve_single_identity(self):
  with tempfile.TemporaryDirectory() as d:
   root=Path(d);file=root/'academic.ics';env=dict(os.environ,HOME=d,SENSEI_CALENDAR_DIR=str(root/'calendar'))
   def run(date,status='CONFIRMED',seq=0):
    file.write_text('BEGIN:VCALENDAR\nX-WR-CALNAME:UIU Undergraduate Trimester\nBEGIN:VEVENT\nUID:uiu-test@noesis\nSEQUENCE:'+str(seq)+'\nDTSTART;VALUE=DATE:'+date+'\nSUMMARY:Exam\nSTATUS:'+status+'\nEND:VEVENT\nEND:VCALENDAR\n')
    return subprocess.run(['python',str(SCRIPT),'import',str(file)],env=env,capture_output=True,text=True,check=True)
   run('20261204');run('20261205',seq=1);run('20261205',seq=1)
   with sqlite3.connect(root/'calendar/calendar.sqlite') as db:
    self.assertEqual(db.execute('select count(*) from events').fetchone()[0],1)
    self.assertEqual(db.execute('select count(*) from import_revisions').fetchone()[0],2)
   run('20261205','CANCELLED',2)
   with sqlite3.connect(root/'calendar/calendar.sqlite') as db:self.assertEqual(db.execute('select done from events').fetchone()[0],1)
 def test_older_revision_cannot_revert_date(self):
  with tempfile.TemporaryDirectory() as d:
   env=dict(os.environ,HOME=d,SENSEI_CALENDAR_DIR=d+'/calendar');f=Path(d)/'test.ics'
   for seq,date in [(3,'20261205'),(2,'20261204')]:
    f.write_text(f'BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:test\nSEQUENCE:{seq}\nDTSTART;VALUE=DATE:{date}\nSUMMARY:Test\nEND:VEVENT\nEND:VCALENDAR')
    subprocess.run(['python',str(SCRIPT),'import',str(f)],env=env,capture_output=True,check=True)
   with sqlite3.connect(d+'/calendar/calendar.sqlite') as db:self.assertEqual(db.execute('select sequence from imported_events').fetchone()[0],3)

 def test_foreign_dateless_cancellation_cannot_cancel_personal_event(self):
  with tempfile.TemporaryDirectory() as d:
   env=dict(os.environ,HOME=d,SENSEI_CALENDAR_DIR=d+'/calendar');f=Path(d)/'test.ics'
   f.write_text('BEGIN:VCALENDAR\nX-WR-CALNAME:Official\nBEGIN:VEVENT\nUID:test\nDTSTART;VALUE=DATE:20261205\nSUMMARY:Test\nEND:VEVENT\nEND:VCALENDAR')
   subprocess.run(['python',str(SCRIPT),'import',str(f)],env=env,capture_output=True,check=True)
   f.write_text('BEGIN:VCALENDAR\nX-WR-CALNAME:Other\nBEGIN:VEVENT\nUID:test\nSTATUS:CANCELLED\nEND:VEVENT\nEND:VCALENDAR')
   result=subprocess.run(['python',str(SCRIPT),'import',str(f)],env=env,capture_output=True)
   self.assertNotEqual(result.returncode,0)
   with sqlite3.connect(d+'/calendar/calendar.sqlite') as db:self.assertEqual(db.execute('select done from events').fetchone()[0],0)

 def test_single_occurrence_cancel_does_not_cancel_series(self):
  with tempfile.TemporaryDirectory() as d:
   env=dict(os.environ,HOME=d,SENSEI_CALENDAR_DIR=d+'/calendar');f=Path(d)/'test.ics'
   f.write_text('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:test\nDTSTART;VALUE=DATE:20261205\nRRULE:FREQ=WEEKLY\nSUMMARY:Class\nEND:VEVENT\nEND:VCALENDAR')
   subprocess.run(['python',str(SCRIPT),'import',str(f)],env=env,capture_output=True,check=True)
   f.write_text('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:test\nRECURRENCE-ID;VALUE=DATE:20261212\nSTATUS:CANCELLED\nEND:VEVENT\nEND:VCALENDAR')
   result=subprocess.run(['python',str(SCRIPT),'import',str(f)],env=env,capture_output=True)
   self.assertNotEqual(result.returncode,0)
   with sqlite3.connect(d+'/calendar/calendar.sqlite') as db:self.assertEqual(db.execute('select done from events').fetchone()[0],0)

def test_removed_import_exception_does_not_remove_local_override(tmp_path):
 env=dict(os.environ,HOME=str(tmp_path),SENSEI_CALENDAR_DIR=str(tmp_path/'calendar'));f=tmp_path/'test.ics'
 def imported(sequence,exception):
  f.write_text('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:weekly-test\nSEQUENCE:'+str(sequence)+'\nDTSTART;VALUE=DATE:20261205\nRRULE:FREQ=WEEKLY\nSUMMARY:Class\n'+exception+'END:VEVENT\nEND:VCALENDAR\n')
  subprocess.run(['python3',str(SCRIPT),'import',str(f)],env=env,capture_output=True,check=True)
 imported(0,'EXDATE;VALUE=DATE:20261212\n')
 with sqlite3.connect(tmp_path/'calendar/calendar.sqlite') as db:
  ident=db.execute('select id from events').fetchone()[0]
  db.execute("insert into exceptions(event,occurrence,source) values(?,?,?)",(ident,123456789,'local'))
 imported(1,'')
 with sqlite3.connect(tmp_path/'calendar/calendar.sqlite') as db:
  assert db.execute('select occurrence,source from exceptions').fetchall()==[(123456789.0,'local')]

def test_failed_recurring_notification_retries_inside_lead_window(tmp_path):
 import datetime,time
 env=dict(os.environ,HOME=str(tmp_path),SENSEI_CALENDAR_DIR=str(tmp_path/'calendar'));f=tmp_path/'test.ics'
 start=(datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(minutes=3)).replace(microsecond=0)
 f.write_text('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:retry-test\nDTSTART:'+start.strftime('%Y%m%dT%H%M%SZ')+'\nRRULE:FREQ=DAILY\nSUMMARY:Retry\nEND:VEVENT\nEND:VCALENDAR\n')
 subprocess.run(['python3',str(SCRIPT),'import',str(f)],env=env,capture_output=True,check=True)
 with sqlite3.connect(tmp_path/'calendar/calendar.sqlite') as db:db.execute('update events set lead=15')
 scheduler=SCRIPT.with_name('sensei-calendar-scheduler')
 result=subprocess.run(['python3',str(scheduler),'--inspect'],env=env,capture_output=True,text=True,check=True)
 assert 0<json.loads(result.stdout)['next']-time.time()<35
 with sqlite3.connect(tmp_path/'calendar/calendar.sqlite') as db:
  ident=db.execute('select id from events').fetchone()[0]
  db.execute('insert into delivered(event,occurrence) values(?,?)',(ident,start.timestamp()))
 result=subprocess.run(['python3',str(scheduler),'--inspect'],env=env,capture_output=True,text=True,check=True)
 assert json.loads(result.stdout)['next']>start.timestamp()
