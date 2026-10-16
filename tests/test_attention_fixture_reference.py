import importlib.util
from pathlib import Path
import unittest,tempfile
from unittest.mock import Mock,patch
spec=importlib.util.spec_from_file_location('attention_fixture',Path(__file__).resolve().parents[1]/'scripts/noesis_attention_fixture.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ReferenceTests(unittest.TestCase):
 def test_section_is_not_misrepresented_as_native_annotation(self):
  from noesis.persistence import migration
  from noesis.models import create
  from noesis.index import Index
  with tempfile.TemporaryDirectory() as tmp,patch('pathlib.Path.home',return_value=Path(tmp)):
   root=Path(tmp)/'vault';(root/'System').mkdir(parents=True);(root/'System/System.json').write_text('{}');migration(root,True)
   paper=create(root,'resource','Paper',fields={'source':'https://example.invalid/paper'})
   index=Index(root)
   try:
    index.reconcile();result=m.reference_fields(index,paper['id'],{'section':'3.2.1'})
   finally:index.close()
   self.assertNotIn('annotation_ref',result)
   self.assertEqual(result['citation_ref']['resource_id'],paper['id'])
   self.assertEqual(result['citation_ref']['section'],'3.2.1')
 def test_incomplete_native_reference_cannot_fall_back_to_section(self):
  with self.assertRaises(ValueError):m.reference_fields(Mock(),'paper-id',{'native_id':'key','section':'3.2.1'})
 def test_missing_resource_or_section_is_rejected(self):
  index=Mock();index.record.return_value=None
  with self.assertRaises(ValueError):m.reference_fields(index,'missing',{'section':'3'})
if __name__=='__main__':unittest.main()
