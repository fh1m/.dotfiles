import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
s=importlib.util.spec_from_file_location("hardware_installer",ROOT/"scripts/install.py")
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class HardwareProfiles(unittest.TestCase):
 def test_profiles_preserve_machine_policies(self):
     with tempfile.TemporaryDirectory() as d:
         for profile in ["zenbook","pc"]:
             home=Path(d)/profile
             m.install(home,True,profile)
             machine=json.loads((home/".config/sensei/machine.json").read_text())
             assert machine["profile"]==profile
             source=(ROOT/"profiles/pc/home/.config/hypr/custom-setup.lua") if profile=="pc" else ROOT/"home/.config/hypr/custom-setup.lua"
             assert (home/".config/hypr/custom-setup.lua").read_bytes()==m.render(source.read_bytes(),home,profile)
             assert m.install(home,True,profile)["changed"]==[]
