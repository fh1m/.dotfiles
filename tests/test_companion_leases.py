import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('leases',ROOT/'home/.local/share/sensei/companion_roam.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Leases(unittest.TestCase):
 def test_stale_journeys_cannot_revive(self):
  a=m.grant({},'DP-1',2,now=10)
  with self.assertRaises(ValueError):m.grant(a,'DP-2',1,now=12)
 def test_expired_or_hidden_lease_is_not_visible(self):
  a=m.grant({},'DP-1',1,ttl=10,now=10);self.assertTrue(m.valid(a,19));self.assertFalse(m.valid(a,20));self.assertFalse(m.valid(m.grant(a,'',2,now=11),12))
 def test_unbounded_lease_is_rejected(self):
  with self.assertRaises(ValueError):m.grant({},'DP-1',1,ttl=10000)

class RepertoireMemory(unittest.TestCase):
    def test_only_bounded_ids_cross_the_lease(self):
        self.assertEqual(m.memory({'turn':'unsafe','recent':['private text',True,-2,7]}),{'turn':0,'recent':[7]})
        self.assertEqual(len(m.memory({'turn':5,'recent':list(range(100))})['recent']),40)
    def test_newer_sequence_wins_without_private_content(self):
        self.assertEqual(m.newer_memory({'turn':4,'recent':[1]},{'turn':5,'recent':[2],'message':'private'}),{'turn':5,'recent':[2]})

class EngineeringReceipts(unittest.TestCase):
 def test_projection_strips_private_data_and_rejects_stale_or_unknown_hosts(self):
  import uuid
  row={'id':str(uuid.uuid4()),'at':95,'host':'arete','kind':'job.completed','data':{'job':'run-1','outcome':'failed','command':'private','log':'private','repeatFailures':3,'failureKey':'a'*64}}
  result=m.engineering_events([row],now=100)[0]
  self.assertNotIn('private',str(result));self.assertEqual(result['data']['repeatFailures'],3)
  self.assertEqual(m.engineering_events([dict(row,host='untrusted')],now=100),[])
  self.assertEqual(m.engineering_events([row],now=300),[])
 def test_ack_ids_are_deduplicated_and_bounded(self):
  import uuid
  ids=[str(uuid.uuid4()) for _ in range(150)]
  self.assertEqual(len(m.engineering_acks(ids)),128)
  self.assertEqual(m.engineering_acks([ids[0],ids[0],'not-a-uuid']),[ids[0]])

class MusicReceipt(unittest.TestCase):
 def test_short_lyrics_only_and_no_account_metadata(self):
  row={'at':1000,'playing':True,'line':'one two three four five six seven eight nine','url':'secret'}
  self.assertEqual(m.music_line(row,now=2000),{'at':1000,'playing':True,'line':'one two three four five six seven eight nine'})
 def test_expired_paused_and_malformed_receipts_are_ignored(self):
  for row in [None,{}, {'at':1000,'playing':False,'line':'x'},{'at':float('nan'),'playing':True,'line':'x'},{'at':1000,'playing':True,'line':42}]:self.assertEqual(m.music_line(row,now=2000),{})
  self.assertEqual(m.music_line({'at':1000,'playing':True,'line':'x'},now=32000),{})

class CurrentLyricLease(unittest.TestCase):
 def test_line_deadline_is_preserved_and_expired_lines_are_not_forwarded(self):
  row={'at':1000,'until':2000,'playing':True,'line':'short line'}
  self.assertEqual(m.music_line(row,now=1500),row)
  self.assertEqual(m.music_line(row,now=2000),{})
  self.assertEqual(m.music_line(dict(row,until=90000),now=1500),{})

class DesktopNoticeReceipt(unittest.TestCase):
 def test_phone_receipt_is_bounded_and_drops_private_fields_outside_requested_text(self):
  row={'unread':4,'dnd':True,'entries':[{'id':'homie:1000:3','at':1000,'phone':True,'app':'KDE Connect','summary':'Message','body':'Hello','actions':['exec'],'token':'private'}]}
  receipt=m.notification_receipt(row,'homie',now=2000)
  self.assertTrue(receipt['dnd']);self.assertEqual(receipt['unread'],4)
  self.assertEqual(receipt['entries'][0]['body'],'Hello');self.assertNotIn('private',str(receipt));self.assertNotIn('actions',str(receipt))
 def test_malformed_stale_and_other_host_notification_ids_rejected(self):
  row={'unread':999,'entries':[{'id':'arete:1000:1','at':1000},{'id':'homie:1000:1','at':float('nan')}]}
  self.assertEqual(m.notification_receipt(row,'homie',now=2000)['entries'],[])
  self.assertEqual(m.notification_receipt({},'unknown'),{})
  self.assertEqual(m.notification_acks(['homie:1000:1','homie:1000:1','unsafe']),['homie:1000:1'])
