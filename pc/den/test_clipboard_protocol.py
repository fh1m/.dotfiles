import base64, importlib.util, json, pathlib, unittest
spec=importlib.util.spec_from_file_location("den_clipboard",pathlib.Path(__file__).with_name("den-clipboard.py"))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Protocol(unittest.TestCase):
    def test_binary_roundtrip_and_content_identity(self):
        data=bytes(range(256))
        frame=json.dumps({"mime":"image/png","data":base64.b64encode(data).decode()})
        mime,result,digest=m.validate(frame)
        self.assertEqual(result,data)
        self.assertEqual(digest,m.validate(frame.encode())[2])
        self.assertNotEqual(digest,m.validate(frame.replace("image/png","text/plain"))[2])
    def test_unrecognized_types_and_corrupt_data_rejected(self):
        for mime,data in [("application/x-command","eA=="),("text/plain","%%%")]:
            with self.assertRaises(ValueError):m.validate(json.dumps({"mime":mime,"data":data}))
    def test_frame_limit(self):
        with self.assertRaises(ValueError):m.validate(b"x"*(m.LIMIT*2+1))
        frame=json.dumps({"mime":"image/png","data":base64.b64encode(b"x"*(m.LIMIT+1)).decode()})
        with self.assertRaises(ValueError):m.validate(frame)
if __name__=="__main__":unittest.main()
