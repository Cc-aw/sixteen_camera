"""Early publication is mandatory; backpressure may postpone hardware enqueue."""
from pathlib import Path
import copy
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from ppu_early_log import validate


class EarlyPpuLogTests(unittest.TestCase):
    def example(self):
        run=dict(ppu_early=1,mode='independent',analysis=0,graph=400,batch=800,ppu_events={})
        run['ppu_early_stats']=dict(published_mask='7',enqueued_mask='7',result_mask='7',
                                   progress_mask='0',progress_sampling='0',service_calls='8',service_cycles='0')
        for w in range(3):
            run['ppu_events'][w]=dict(worker=str(w),graph_done_cycles=str((w+1)*100),
                publication_commit_cycles=str((w+1)*100+10),enqueue_cycles=str(500+w*10),
                result_observed_cycles=str(600+w*20),enqueue_done_mask='7',result_done_mask='7',
                progress_cycles='0',progress_done_mask='0')
        return run

    def test_queue_backpressure_can_defer_admission_past_graph_end(self):
        validate(self.example())

    def test_timestamp_order_bounds_and_masks_are_strict(self):
        original=self.example()
        for field,value in (('publication_commit_cycles','401'),('enqueue_cycles','99'),
                            ('result_observed_cycles','801'),('result_done_mask','1'),
                            ('progress_cycles','1'),('graph_done_cycles','-1')):
            run=copy.deepcopy(original);run['ppu_events'][0][field]=value
            with self.subTest(field=field), self.assertRaises(ValueError):validate(run)
        for field,value in (('service_cycles','1'),('progress_mask','8'),('published_mask','3'),
                            ('service_calls','0'),('progress_sampling','1')):
            run=copy.deepcopy(original);run['ppu_early_stats'][field]=value
            with self.subTest(field=field), self.assertRaises(ValueError):validate(run)

    def test_disabled_and_other_modes_reject_early_records(self):
        for change in ({'ppu_early':0},{'mode':'forward'}):
            run=self.example();run.update(change)
            with self.assertRaises(ValueError):validate(run)


if __name__=='__main__':unittest.main()
