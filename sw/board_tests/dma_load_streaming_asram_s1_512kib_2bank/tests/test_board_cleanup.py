"""No hardware access: cleanup must include children of exited download launchers."""
from pathlib import Path
import signal
import subprocess
import sys
import unittest
from unittest.mock import MagicMock, call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import run_board


class BoardCleanup(unittest.TestCase):
    def test_owned_group_is_stopped_when_launcher_has_already_exited(self):
        process=MagicMock(pid=43571)
        process.poll.return_value=0
        with patch.object(run_board.os,'killpg') as kill:
            run_board.stop_download(process)
        self.assertEqual(kill.call_args_list,[call(process.pid,signal.SIGTERM),
                                             call(process.pid,signal.SIGKILL)])
        process.wait.assert_any_call(timeout=10)

    def test_timeout_and_missing_group_are_handled(self):
        process=MagicMock(pid=43572)
        process.wait.side_effect=[subprocess.TimeoutExpired('fixture',10),0]
        with patch.object(run_board.os,'killpg',side_effect=ProcessLookupError) as kill:
            run_board.stop_download(process)
            run_board.stop_download(None)
        self.assertEqual(kill.call_count,2)
        self.assertEqual(process.wait.call_count,2)
