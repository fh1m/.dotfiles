import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import patch
from urllib.request import Request,urlopen
from urllib.error import HTTPError
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'home/.local/share/sensei'))
import spotify_bridge as bridge
import spotify_catalog as catalog

class Relay(unittest.TestCase):
 def setUp(self):
  self.server=bridge.create_server({'port':0,'secret':'owned-test-secret'})
  self.thread=threading.Thread(target=self.server.serve_forever,daemon=True);self.thread.start()
  self.url='http://127.0.0.1:'+str(self.server.server_port)
 def tearDown(self):self.server.shutdown();self.server.server_close();self.thread.join()
 def post(self,path,body,secret='owned-test-secret',host=None):
  headers={'Authorization':'Bearer '+secret,'Content-Type':'application/json'}
  if host:headers['Host']=host
  with urlopen(Request(self.url+path,data=json.dumps(body).encode(),headers=headers),timeout=3) as response:return json.load(response)
 def test_authentication_required(self):
  with self.assertRaises(HTTPError) as error:self.post('/request',{'operation':'probe'},'wrong')
  self.assertEqual(error.exception.code,403);error.exception.close()
 def test_dns_rebinding_host_rejected(self):
  with self.assertRaises(HTTPError) as error:self.post('/request',{'operation':'probe'},host='attacker.example')
  self.assertEqual(error.exception.code,403);error.exception.close()
 def test_arbitrary_javascript_is_not_an_operation(self):
  with self.assertRaises(HTTPError) as error:self.post('/request',{'operation':'eval','args':['steal()']})
  self.assertEqual(error.exception.code,400);error.exception.close()
 def test_non_object_json_is_rejected(self):
  with self.assertRaises(HTTPError) as error:self.post('/request',[])
  self.assertEqual(error.exception.code,400);error.exception.close()
 def test_disconnected_client_fails_without_queued_action(self):
  result=self.post('/request',{'operation':'play-list','args':['{}']})
  self.assertIn('disconnected',result['error'])
 def test_authenticated_round_trip(self):
  errors=[]
  def desktop():
   try:
    command=self.post('/poll',{})
    self.post('/result',{'id':command['id'],'result':{'rows':[{'id':'fixture'}]}})
   except Exception as error:errors.append(error)
  worker=threading.Thread(target=desktop,daemon=True);worker.start()
  for _ in range(30):
   result=self.post('/request',{'operation':'library','args':['liked']})
   if not result.get('error'):break
   time.sleep(.01)
  worker.join(timeout=3);self.assertFalse(errors);self.assertEqual(result['rows'][0]['id'],'fixture')

class Catalogue(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.p=patch.object(catalog,'STORE',Path(self.temp.name));self.p.start()
 def tearDown(self):self.p.stop();self.temp.cleanup()
 def test_cached_browsing_does_not_repeat_a_request(self):
  with patch.object(catalog,'request',return_value={'rows':[{'id':'one'}],'kind':'liked'}) as request:
   catalog.dispatch(['library','liked']);catalog.dispatch(['library','liked']);self.assertEqual(request.call_count,1)
 def test_unavailable_desktop_preserves_saved_rows(self):
  with patch.object(catalog,'request',return_value={'rows':[{'id':'one'}]}):catalog.dispatch(['library','liked'])
  with patch.object(catalog,'request',side_effect=OSError('offline')):
   result=catalog.dispatch(['library','liked','refresh'])
  self.assertTrue(result['stale']);self.assertEqual(result['rows'][0]['id'],'one')
 def test_rate_limit_cools_all_reads_without_replaying_actions(self):
  with patch.object(catalog,'request',return_value={'error':'429 Too Many Requests'}) as request:
   first=catalog.dispatch(['library','liked','refresh'])
   second=catalog.dispatch(['search','different query'])
  self.assertEqual(request.call_count,1);self.assertIn('pause',first['error']);self.assertGreater(second['retryAfter'],0)
 def test_cooldown_preserves_cached_library(self):
  with patch.object(catalog,'request',return_value={'rows':[{'id':'kept'}]}):catalog.dispatch(['library','liked'])
  with patch.object(catalog,'request',return_value={'error':'QUOTA_EXCEEDED'}):result=catalog.dispatch(['library','liked','refresh'])
  self.assertTrue(result['stale']);self.assertEqual(result['rows'][0]['id'],'kept')
 def test_more_never_follows_a_web_api_url(self):
  with patch.object(catalog,'request') as request:
   with self.assertRaises(ValueError):catalog.dispatch(['more','https://api.spotify.com/v1/me/tracks'])
   request.assert_not_called()
 def test_playlist_pagination_retains_context_identity(self):
  ident='A'*22
  with patch.object(catalog,'request',return_value={'rows':[]}) as request:
   result=catalog.dispatch(['more','desktop:context:playlist:'+ident+':100','track','context',ident])
  request.assert_called_once_with('context',['playlist',ident,100]);self.assertEqual(result['contextId'],ident)

class Extension(unittest.TestCase):
 def evaluate(self,operation,args,platform,graphql=None):
  harness=r'''
const fs=require('fs'),vm=require('vm');const f=JSON.parse(fs.readFileSync(0,'utf8'));
const P={ConnectAPI:{getState:()=>f.platform.connect||{}},RootlistAPI:{getContents:async()=>f.platform.root||{items:[]}},LibraryAPI:{getTracks:async()=>f.platform.tracks||{items:[]}}};
const fetch=async(url,request)=>({ok:true,json:async()=>{if(url.endsWith('/poll'))return {id:'fixture',operation:f.operation,args:f.args};console.log(JSON.stringify(JSON.parse(request.body).result));process.exit(0);}});
const context={Spicetify:{Platform:P,GraphQL:{Definitions:{searchModalResults:{}},Request:async()=>f.graphql||{}},Config:{}},fetch,setTimeout};context.globalThis=context;
vm.runInNewContext(fs.readFileSync(f.source,'utf8').replace('__PORT__','1').replace('__SECRET__','fixture'),context);
'''
  data={'source':str(ROOT/'home/.local/share/sensei-spotify/bridge.js'),'operation':operation,'args':args,'platform':platform,'graphql':graphql}
  return json.loads(subprocess.check_output(['node','-e',harness],input=json.dumps(data),text=True,timeout=5))
 def test_unknown_native_total_does_not_truncate_liked_songs(self):
  items=[{'type':'track','uri':'spotify:track:'+str(i).zfill(22),'name':'fixture'} for i in range(100)]
  result=self.evaluate('library',['liked'],{'tracks':{'items':items,'totalLength':0}})
  self.assertEqual(len(result['rows']),100);self.assertEqual(result['next'],'desktop:liked:100');self.assertFalse(result['complete'])
 def test_nested_playlist_folder_is_flattened_without_losing_playlist(self):
  result=self.evaluate('library',['playlists'],{'root':{'items':[{'type':'folder','items':[{'type':'playlist','uri':'spotify:playlist:'+'A'*22,'name':'fixture'}]}]}})
  self.assertEqual(len(result['rows']),1)
 def test_local_device_is_not_automatically_the_active_device(self):
  result=self.evaluate('devices',[],{'connect':{'activeDevice':{'id':'remote'},'devices':[{'id':'local','isLocal':True},{'id':'remote','isLocal':False}]}})
  self.assertFalse(result['rows'][0]['is_active']);self.assertTrue(result['rows'][1]['is_active'])
 def test_search_wrapper_preserves_entity_type(self):
  result=self.evaluate('search',['fixture'],{}, {'data':{'searchV2':{'topResultsV2':{'itemsV2':[{'item':{'data':{'uri':'spotify:album:'+'A'*22,'name':'fixture'}}}]}}}})
  self.assertEqual(len(result['albums']),1);self.assertEqual(result['tracks'],[])
