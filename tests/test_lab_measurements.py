import json,os,subprocess,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class LabMeasures(unittest.TestCase):
 def test_real_run_and_baseline_preserve_execution_and_units(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);project=root/'project';project.mkdir();env={**os.environ,'XDG_STATE_HOME':str(root/'state'),'SENSEI_ENGINEERING_HOME':str(root)}
   code='import json;from pathlib import Path;Path("metrics.json").write_text(json.dumps([dict(name="drift",value=0.02,unit="m/s")]))'
   argv=[str(ROOT/'home/.local/bin/sensei-lab'),'run','--project',str(project),'--metrics','metrics.json','--',sys.executable,'-c',code]
   first=subprocess.run(argv,env=env,capture_output=True,text=True,timeout=10);self.assertEqual(first.returncode,0,first.stderr)
   baseline=next((root/'state/sensei-lab').glob('*/run.json'));a=json.loads(baseline.read_text());self.assertEqual(a['measurements'][0]['unit'],'m/s');self.assertEqual(a['status'],'passed')
   second=argv[:argv.index('--')]+['--baseline',str(baseline)]+argv[argv.index('--'):]
   result=subprocess.run(second,env=env,capture_output=True,text=True,timeout=10);self.assertEqual(result.returncode,0,result.stderr)
   rows=[json.loads(p.read_text()) for p in (root/'state/sensei-lab').glob('*/run.json')];comparison=next(r for r in rows if 'comparison' in r)
   self.assertEqual(comparison['comparison'][0]['delta'],0)
