import json,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import twitch_media as t
class TwitchMedia(unittest.TestCase):
 def test_identity_is_not_a_general_extractor_or_shell(self):
  self.assertEqual(t.identity('https://www.twitch.tv/Roboticists'),'roboticists')
  self.assertEqual(t.identity('https://twitch.tv/videos/123456'),'videos/123456')
  for value in ['https://evil.invalid/roboticists','--exec=bad','../../file','https://twitch.tv.evil.invalid/channel']:
   with self.assertRaises(ValueError):t.identity(value)
 def test_live_status_and_viewer_count_are_distinct_from_duration(self):
  row=t.row({'login':'roboticists','stream':{'title':'Building','viewersCount':12,'game':{'name':'Engineering'}}})
  self.assertTrue(row['live']);self.assertEqual(row['viewers'],12);self.assertEqual(row['duration'],0)
 def test_stream_requires_an_allowed_https_cdn(self):
  import subprocess
  for url in ['https://attacker.invalid/file','http://video.ttvnw.net/stream','https://ttvnw.net.evil.invalid/file']:
   result=subprocess.CompletedProcess([],0,json.dumps({'url':url}),'')
   with patch.object(t.subprocess,'run',return_value=result):
    with self.assertRaises(ValueError):t.stream('roboticists')
 def test_public_stream_does_not_extract_or_export_browser_tokens(self):
  import subprocess
  result=subprocess.CompletedProcess([],0,json.dumps({'url':'https://video.ttvnw.net/stream','is_live':True}),'')
  with patch.object(t.subprocess,'run',return_value=result) as run,patch.object(t,'session') as session:
   record=t.stream('roboticists');self.assertTrue(record['combined']);session.assert_not_called();self.assertNotIn('cookies',' '.join(run.call_args.args[0]));self.assertIn('--print',run.call_args.args[0]);self.assertNotIn('--dump-single-json',run.call_args.args[0])
 def test_local_bookmark_deduplicates_without_saving_signed_streams(self):
  with tempfile.TemporaryDirectory() as d,patch.object(t,'LIBRARY',Path(d)/'saved.json'):
   t.saved({'id':'roboticists','stream':'SECRET','title':'one'});t.saved({'id':'roboticists','title':'two'})
   self.assertEqual(len(t.saved()['rows']),1);self.assertNotIn('SECRET',t.LIBRARY.read_text())
 def test_no_session_is_not_reported_as_connected(self):
  with patch.object(t,'session',return_value=None):self.assertFalse(t.account_status()['connected'])
 def test_following_is_explicitly_authenticated_and_live_first(self):
  with tempfile.TemporaryDirectory() as d,patch.object(t,'CACHE',Path(d)),patch.object(t,'gql',return_value={'currentUser':{'follows':{'edges':[{'node':{'login':'offline'}},{'node':{'login':'online','stream':{'viewersCount':2}}}]}}}) as g:
   rows=t.browse('following')['rows'];self.assertEqual(rows[0]['id'],'online');self.assertTrue(g.call_args.kwargs['private'])
 def test_signed_in_playback_uses_extractor_cookie_jar_not_a_global_auth_header(self):
  import subprocess
  record=subprocess.CompletedProcess([],0,json.dumps({'url':'https://video.ttvnw.net/stream','is_live':True}),'')
  with patch.object(t,'browser_account',return_value={'profile':'Default'}),patch.object(t.subprocess,'run',return_value=record) as run:
   t.stream('roboticists',authenticated=True);argv=run.call_args.args[0];self.assertIn('--cookies-from-browser',argv);self.assertIn('chrome+gnomekeyring:Default',argv);self.assertNotIn('--add-header',argv)
if __name__=='__main__':unittest.main()
