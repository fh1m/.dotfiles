import sys,unittest,tempfile,json
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'home/.local/share/sensei'))
import spotify_headless as h
class Headless(unittest.TestCase):
 def test_status_is_local_and_metadata_complete(self):
  data={'stopped':False,'paused':False,'volume':30,'volume_steps':100,'track':{'uri':'spotify:track:'+'a'*22,'name':'Song','duration':120000,'position':4000,'artist_names':['Artist']}}
  with patch.object(h,'request',return_value=data) as req:
   d=h.status();self.assertTrue(d['playing']);self.assertEqual(d['track']['title'],'Song');self.assertEqual(d['progress'],4000);self.assertGreater(d['eventTime'],0);req.assert_called_once_with('/status')
 def test_skip_is_exactly_once_even_on_failure(self):
  with patch.object(h,'raw_status',return_value={'track':{'uri':'old'}}),patch.object(h,'request',side_effect=ValueError('uncertain')) as req:
   with self.assertRaises(ValueError):h.dispatch(['next','playing'])
   req.assert_called_once_with('/player/next',{})
 def test_uri_rejects_arbitrary_input(self):
  for k,v in [('track','../secret'),('file','a'*22),('track','http://evil')]:
   with self.assertRaises(ValueError):h.uri(k,v)
 def test_playlist_preserves_context_and_skip_uri(self):
  with patch.object(h,'raw_status',return_value={'track':{'uri':'old'}}),patch.object(h,'mark_intent'),patch.object(h,'request',return_value={}) as req:
   h.dispatch(['play-context-track','playlist','a'*22,'spotify:track:'+'b'*22])
   req.assert_called_once_with('/player/play',{'uri':'spotify:playlist:'+'a'*22,'skip_to_uri':'spotify:track:'+'b'*22})
 def test_saved_rows_survive_offline(self):
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)):
   h.cache('library',lambda:{'rows':[{'title':'Saved'}]},ttl=0)
   def fail():raise ValueError('offline')
   x=h.cache('library',fail,ttl=0);self.assertTrue(x['stale']);self.assertEqual(x['rows'][0]['title'],'Saved')
 def test_queue_payload_is_validated_before_mutation(self):
  with patch.object(h,'request') as req:
   with self.assertRaises(ValueError):h.dispatch(['play-list',json.dumps({'uris':['spotify:track:'+'a'*22,'bad'],'offset':0})])
   req.assert_not_called()
 def test_unknown_write_does_not_mutate(self):
  with patch.object(h,'request') as req:
   with self.assertRaises(ValueError):h.dispatch(['playlist-create','private'])
   req.assert_not_called()
 def test_pending_transition_preserves_loading_until_new_track(self):
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)):
   h.mark_intent({'track':{'uri':'old'}},'next')
   self.assertTrue(h.transitioning({'track':{'uri':'old'}}))
   self.assertFalse(h.transitioning({'track':{'uri':'new'},'buffering':False}))
   self.assertFalse((Path(d)/'intent.json').exists())
 def test_context_pagination_keeps_unresolved_tracks_and_duplicates(self):
  u='spotify:track:'+'a'*22
  with patch.object(h,'request',return_value={'ready':True,'cached':0,'total':575,'tracks':[{'uri':u},{'uri':u}]}) as req:
   result=h.listing('spotify:collection:tracks',50)
   self.assertEqual(len(result['rows']),2);self.assertTrue(result['partial'])
   token=json.loads(result['next'][9:]);self.assertEqual(token['offset'],52)
   self.assertIn('offset=50',req.call_args.args[0])
 def test_invalid_pagination_does_not_request(self):
  with patch.object(h,'request') as req:
   with self.assertRaises(ValueError):h.dispatch(['more','headless:{"offset":-1,"type":"library","kind":"liked"}'])
   req.assert_not_called()
 def test_catalogue_failure_retains_local_search(self):
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)),patch.object(h,'catalogue_search',side_effect=ValueError('offline')):
   h.cache('library',lambda:{'rows':[{'uri':'spotify:track:'+'a'*22,'kind':'track','title':'Example','artist':'A'}]})
   result=h.dispatch(['search','Example','tracks']);self.assertEqual(len(result['tracks']),1);self.assertEqual(result['warning'],'offline')
 def test_resume_at_saved_position_clears_loading(self):
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)):
   h.mark_intent({'track':{'uri':'same'}},'start','spotify:collection:tracks',90000)
   self.assertFalse(h.transitioning({'track':{'uri':'same','position':90200},'context_uri':'spotify:collection:tracks'}))
 def test_playlist_queue_is_one_atomic_request(self):
  values=['spotify:track:'+'a'*22,'spotify:track:'+'b'*22,'spotify:track:'+'b'*22]
  with patch.object(h,'request',return_value={}) as req:
   h.dispatch(['play-list',json.dumps(values)])
   req.assert_called_once_with('/player/play',{'uri':values[0],'queued':values[1:]})
 def test_stopped_resume_uses_saved_position_and_queue_without_replaying_skips(self):
  saved={'track':{'uri':'spotify:track:'+'a'*22,'position':42000},'queue':[{'uri':'spotify:track:'+'b'*22}]}
  with patch.object(h,'raw_status',return_value={'stopped':True}),patch.object(h,'remembered_playback',return_value=saved),patch.object(h,'mark_intent'),patch.object(h,'request') as req:
   self.assertTrue(h.dispatch(['play'])['restored'])
   req.assert_called_once_with('/player/play',{'uri':saved['track']['uri'],'position':42000,'queued':[saved['queue'][0]['uri']]})
 def test_transition_cannot_erase_saved_queue(self):
  saved={'stopped':False,'track':{'uri':'spotify:track:'+'a'*22},'queue':[{'uri':'spotify:track:'+'b'*22}]}
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)):
   h.remember_playback(saved)
   h.remember_playback({'stopped':False,'buffering':True,'track':{'uri':'new'},'queue':[]})
   self.assertEqual(h.remembered_playback()['queue'],saved['queue'])
   with patch.object(h,'raw_status',return_value={'stopped':True}):
    result=h.dispatch(['queue']);self.assertTrue(result['stale']);self.assertEqual(len(result['rows']),1)
 def test_recovery_is_rate_limited_across_calls(self):
  with tempfile.TemporaryDirectory() as d,patch.object(h,'STORE',Path(d)),patch('subprocess.run') as run,patch.object(h.time,'sleep'):
   run.return_value.returncode=0
   self.assertTrue(h.recover_service());self.assertFalse(h.recover_service());self.assertEqual(run.call_count,1)
 def test_uncertain_write_is_never_replayed_or_restarted(self):
  import urllib.error
  with patch.object(h.HTTP,'open',side_effect=urllib.error.URLError('offline')) as http,patch.object(h,'recover_service') as recovery:
   with self.assertRaises(ValueError):h.request('/player/next',{})
   self.assertEqual(http.call_count,1);recovery.assert_not_called()
 def test_recovery_waits_for_login_without_restarting_again(self):
  with patch.object(h,'request',side_effect=[ValueError('Music needs a Spotify sign-in.'),{'stopped':True}]) as request,patch.object(h.time,'sleep'):
   self.assertEqual(h.recovered_status(),{'stopped':True});self.assertEqual(request.call_count,2)
if __name__=='__main__':unittest.main()
