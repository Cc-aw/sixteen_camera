import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from run_board import sample_result,startup_command
class BoardLogTests(unittest.TestCase):
 def setUp(self):
  self.lines=['S1RT,READY,continuous=1','S1RT,GUARDS_PASS,asram=1','S1RT,STREAM,stream=15,dispatched=101,completed=101,frame=900,version=101,detections=2','S1RT,SAMPLE_END,completed=101,errors=0,idle=1,held_tensor=0,heads=0']
 def test_continuous_does_not_request_sample(self):self.assertEqual(startup_command(True),b'')
 def test_sample_requests_100(self):self.assertEqual(startup_command(False),b'b')
 def test_completion(self):self.assertEqual(sample_result(self.lines)['active_streams'],[15])
 def test_incomplete(self):self.assertIsNone(sample_result(self.lines[:-1]))
 def test_missing_guards(self):self.assertIsNone(sample_result(self.lines[:1]+self.lines[2:]))
 def test_fault(self):self.assertIsNone(sample_result(self.lines+['S1RT,FAULT,reason=9']))
 def test_errors(self):self.assertIsNone(sample_result([s.replace('errors=0','errors=1') for s in self.lines]))
 def test_held_head(self):self.assertIsNone(sample_result([s.replace('heads=0','heads=1') for s in self.lines]))
 def test_no_streams(self):self.assertIsNone(sample_result([s for s in self.lines if not s.startswith('S1RT,STREAM')]))
 def test_too_few(self):self.assertIsNone(sample_result([s.replace('completed=101','completed=99') for s in self.lines]))
if __name__=='__main__':unittest.main()
