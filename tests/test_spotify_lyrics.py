import json,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import spotify_lyrics as l
import spotify_video as v
TRACK={'title':'A Song','artist':'An Artist','duration':180000}
class Lyrics(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
  self.p1=patch.object(l,'CACHE',Path(self.temp.name)/'cache');self.p2=patch.object(l,'LOCAL',Path(self.temp.name)/'local');self.p1.start();self.p2.start();self.addCleanup(self.p1.stop);self.addCleanup(self.p2.stop)
 def test_parser_multiple_stamps_unicode_offset(self):
  d=l.parse({'syncedLyrics':'[offset:-100]\n[00:01.25][00:02.50]বাংলা'})
  self.assertEqual([x['time'] for x in d['lines']],[1150,2400]);self.assertEqual(d['lines'][0]['text'],'বাংলা')
 def test_exact_lyrics_cached_without_repeat_request(self):
  with patch.object(l,'fetch',return_value={'syncedLyrics':'[00:01]Words'}) as f:
   self.assertTrue(l.lookup(TRACK)['synced']);l.lookup(TRACK);self.assertEqual(f.call_count,1)
 def test_search_rejects_wrong_recording(self):
  items=[{'trackName':'A Song','artistName':'An Artist','duration':360,'syncedLyrics':'wrong'},{'trackName':'A Song','artistName':'Other Person','duration':180,'plainLyrics':'wrong'}]
  self.assertIsNone(l.choose(items,'A Song','An Artist',180))
 def test_plain_provider_fallback_never_invents_timing(self):
  with patch.object(l,'fetch',side_effect=[None,[],{'lyrics':'Plain words'}]):
   d=l.lookup(TRACK);self.assertFalse(d['synced']);self.assertEqual(d['plain'],'Plain words');self.assertEqual(d['provider'],'lyrics.ovh')
 def test_provider_outage_keeps_positive_cache(self):
  l.atomic(l.CACHE/(l.identity(TRACK)+'.json'),{'lines':[],'plain':'Saved','synced':False})
  with patch.object(l,'fetch',side_effect=OSError('offline')):
   d=l.lookup(TRACK,True);self.assertEqual(d['plain'],'Saved');self.assertIn('Saved',d['notice'])
 def test_local_override_and_persistent_offset(self):
  l.LOCAL.mkdir();(l.LOCAL/'An Artist - A Song.lrc').write_text('[00:02]Local')
  l.save_offset(TRACK,-250)
  with patch.object(l,'fetch') as f:
   d=l.lookup(TRACK);self.assertEqual(d['provider'],'Local');self.assertEqual(d['offset'],-250);f.assert_not_called()
 def test_instrumental_is_valid_not_an_error(self):
  with patch.object(l,'fetch',return_value={'instrumental':True}):self.assertTrue(l.lookup(TRACK)['instrumental'])
 def test_versions_have_separate_timing_cache(self):
  self.assertNotEqual(l.identity(TRACK),l.identity(dict(TRACK,duration=300000)))
class Videos(unittest.TestCase):
 def test_untrusted_video_identity_cannot_launch(self):
  with patch.object(v.subprocess,'Popen') as p:
   with self.assertRaises(ValueError):v.launch('../shell')
   p.assert_not_called()
 def test_failed_stream_does_not_open_broken_player(self):
  with patch.object(v.shutil,'which',return_value='/bin/mpv'),patch.object(v.subprocess,'run',side_effect=OSError('offline')),patch.object(v.subprocess,'Popen') as p:
   self.assertFalse(v.launch('a'*11)['ok']);p.assert_not_called()
 def test_video_discovery_failure_is_nonfatal(self):
  with tempfile.TemporaryDirectory() as d,patch.object(v,'CACHE',Path(d)),patch.object(v.shutil,'which',return_value='/bin/yt-dlp'),patch.object(v.subprocess,'run',side_effect=OSError('offline')):
   result=v.candidates(TRACK);self.assertEqual(result['rows'],[]);self.assertIn('unavailable',result['warning'])
 def test_resolver_rejects_non_video_host(self):
  from subprocess import CompletedProcess
  with patch.object(v.subprocess,'run',return_value=CompletedProcess([],0,json.dumps({'url':'https://attacker.invalid/video'}),'')):
   self.assertFalse(v.resolve('a'*11)['ok'])
 def test_resolver_accepts_only_validated_video_stream(self):
  from subprocess import CompletedProcess
  with patch.object(v.subprocess,'run',return_value=CompletedProcess([],0,json.dumps({'url':'https://test.googlevideo.com/video'}),'')):
   self.assertTrue(v.resolve('a'*11)['ok'])
if __name__=='__main__':unittest.main()
