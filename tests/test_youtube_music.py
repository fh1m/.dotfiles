import json,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import youtube_music as y
class YouTube(unittest.TestCase):
 def test_identity_rejects_arbitrary_hosts_and_shell_arguments(self):
  for value in ['https://attacker.invalid/watch?v=abcdefghijk','http://youtube.com/watch?v=abcdefghijk','--exec=evil','../shell']:
   with self.assertRaises(ValueError):y.identity(value)
  self.assertEqual(y.identity('https://youtu.be/abcdefghijk'),'abcdefghijk')
 def test_audio_stream_must_come_from_video_cdn(self):
  with patch.object(y,'run',return_value={'id':'abcdefghijk','url':'https://attacker.invalid/file'}):
   with self.assertRaises(ValueError):y.audio('abcdefghijk')
 def test_failed_search_preserves_cached_results(self):
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'run',return_value={'entries':[{'id':'abcdefghijk','title':'Saved'}]}):
   y.search('example')
   with patch.object(y,'run',side_effect=ValueError('offline')):
    result=y.search('example',True);self.assertEqual(result['rows'][0]['title'],'Saved');self.assertIn('offline',result['warning'])
 def test_duplicate_bookmarks_update_without_stream_credentials(self):
  with tempfile.TemporaryDirectory() as d,patch.object(y,'LIBRARY',Path(d)/'library.json'):
   item={'id':'abcdefghijk','title':'First','stream':'secret-signed-url'};y.save(item);y.save(dict(item,title='Updated'))
   text=y.LIBRARY.read_text();record=json.loads(text);self.assertEqual(len(record['rows']),1);self.assertEqual(record['rows'][0]['title'],'Updated');self.assertNotIn('secret',text)
   y.save(item,True);self.assertEqual(json.loads(y.LIBRARY.read_text())['rows'],[])
 def test_playlist_is_explicitly_bounded(self):
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'run',return_value={'entries':[]}) as r:
   result=y.search('https://www.youtube.com/playlist?list=PLabcdefghijklmno');self.assertIn('50',result['warning']);self.assertIn('50',r.call_args.args[0])
 def test_foreign_url_cannot_become_an_extractor_target(self):
  with patch.object(y,'run') as r:
   with self.assertRaises(ValueError):y.search('https://attacker.invalid/file')
   r.assert_not_called()

class MediaBoundaries(unittest.TestCase):
 def test_collection_pagination_keeps_private_access(self):
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'account',return_value={'profile':'Default'}),patch.object(y,'run',return_value={'entries':[{'id':'abcdefghijk'}]*50}) as r:
   result=y.search('https://youtube.com/playlist?list=PLabcdefghijklmno',authenticated=True,offset=50)
   self.assertEqual(result['next'],100);self.assertTrue(result['rows'][0]['private']);self.assertTrue(r.call_args.args[1]);self.assertIn('51',r.call_args.args[0]);self.assertIn('100',r.call_args.args[0])
 def test_private_video_playback_passes_auth_only_to_extractor(self):
  with patch.object(y,'run',return_value={'id':'abcdefghijk','url':'https://r1.googlevideo.com/stream','acodec':'aac'}) as r:
   result=y.audio('abcdefghijk',authenticated=True);self.assertTrue(r.call_args.args[1]);self.assertTrue(result['track']['private']);self.assertNotIn('cookies',str(result))
 def test_paired_stream_validates_both_cdn_hosts(self):
  data={'id':'abcdefghijk','requested_formats':[{'url':'https://r1.googlevideo.com/video','vcodec':'h264','acodec':'none'},{'url':'https://r2.googlevideo.com/audio','vcodec':'none','acodec':'aac'}]}
  with patch.object(y,'run',return_value=data):
   self.assertIn('video',y.audio('abcdefghijk',True,720));data['requested_formats'][0]['url']='https://googlevideo.com.evil.invalid/file'
   with self.assertRaises(ValueError):y.audio('abcdefghijk',True,720)
 def test_vtt_captions_keep_times_and_strip_markup(self):
  lines=y.parse_vtt('WEBVTT\n\n00:01.250 --> 00:04.000\n<c>Hello &amp; goodbye</c>\n\n01:02:03.004 --> 01:02:04.000\nNext\n')
  self.assertEqual(lines,[{'time':1250,'text':'Hello & goodbye'},{'time':3723004,'text':'Next'}])
 def test_collection_page_bounds_prevent_unbounded_imports(self):
  with self.assertRaises(ValueError):y.collections('watchlater',-1)
  with self.assertRaises(ValueError):y.search('example',offset=10000)

class CompactPayloads(unittest.TestCase):
 def test_stream_resolution_omits_full_format_inventory_and_preflight_requests(self):
  with patch.object(y,'run',return_value={'id':'abcdefghijk','url':'https://r1.googlevideo.com/a','acodec':'aac'}) as r:
   y.audio('abcdefghijk');args=r.call_args.args[0]
   self.assertNotIn('--check-formats',args);self.assertIn('--print',args);self.assertNotIn('automatic_captions',args[args.index('--print')+1])
 def test_catalog_dump_is_projected_before_crossing_process_boundary(self):
  from subprocess import CompletedProcess
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y.subprocess,'run',return_value=CompletedProcess([],0,'{"entries":[]}','')) as r:
   y.run(['--flat-playlist','--dump-single-json','example'])
   cmd=r.call_args.args[0];self.assertNotIn('--dump-single-json',cmd);self.assertIn(y.CATALOG_TEMPLATE,cmd)
 def test_real_template_discards_an_oversized_unneeded_format_list(self):
  try:import yt_dlp
  except ImportError:self.skipTest('yt-dlp is optional in isolated unit environments')
  with yt_dlp.YoutubeDL({'quiet':True}) as downloader:
   data={'id':'abcdefghijk','title':'Long lecture','formats':[{'fragments':['x'*9000000]}],'description':'x'*9000000,'url':'https://r1.googlevideo.com/a'}
   text=downloader.evaluate_outtmpl(y.PLAYBACK_TEMPLATE,data)
   self.assertLess(len(text),1000);self.assertEqual(json.loads(text)['id'],'abcdefghijk')

class AuthenticationFallback(unittest.TestCase):
 def test_bot_challenge_retries_selected_account_once_and_remembers_requirement(self):
  from subprocess import CompletedProcess
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'account',return_value={'profile':'Default'}),patch.object(y.subprocess,'run',side_effect=[CompletedProcess([],1,'',"Sign in to confirm you're not a bot"),CompletedProcess([],0,'{"id":"abcdefghijk"}',''),CompletedProcess([],0,'{"id":"abcdefghijk"}','')]) as r:
   self.assertTrue(y.run(['--dump-single-json','example'])['_authenticated'])
   self.assertNotIn('--cookies-from-browser',r.call_args_list[0].args[0]);self.assertIn('--cookies-from-browser',r.call_args_list[1].args[0])
   self.assertTrue(y.run(['--dump-single-json','example'])['_authenticated']);self.assertEqual(r.call_count,3)
   self.assertEqual(set(json.loads((Path(d)/'auth-required.json').read_text())),{'at'})
 def test_authenticated_failure_never_retries_or_exposes_diagnostic_secrets(self):
  from subprocess import CompletedProcess
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'account',return_value={'profile':'Default'}),patch.object(y.subprocess,'run',return_value=CompletedProcess([],1,'','secret-cookie')) as r:
   with self.assertRaises(ValueError) as error:y.run([],True)
   self.assertNotIn('secret-cookie',str(error.exception));self.assertEqual(r.call_count,1)
 def test_translated_subtitle_expansion_is_disabled_before_response_limit(self):
  from subprocess import CompletedProcess
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y.subprocess,'run',return_value=CompletedProcess([],0,'{}','')) as r:
   y.run(['--dump-single-json','example'])
   self.assertIn('youtube:skip=translated_subs',r.call_args.args[0])
 def test_unrelated_public_failure_does_not_read_browser_credentials(self):
  from subprocess import CompletedProcess
  with tempfile.TemporaryDirectory() as d,patch.object(y,'CACHE',Path(d)),patch.object(y,'account') as account,patch.object(y.subprocess,'run',return_value=CompletedProcess([],1,'','HTTP Error 429')) as r:
   with self.assertRaises(ValueError):y.run([])
   self.assertEqual(r.call_count,1);account.assert_not_called()

if __name__=='__main__':unittest.main()
