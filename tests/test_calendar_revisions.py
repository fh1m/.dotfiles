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
