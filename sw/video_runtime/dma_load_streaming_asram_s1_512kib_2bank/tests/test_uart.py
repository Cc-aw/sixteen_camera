"""UART regressions use mocks and a disposable PTY, never the board port."""
import copy
import fcntl
import os
from pathlib import Path
import pty
import select
import sys
import termios
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from uart import SerialPort


class UartTests(unittest.TestCase):
    def test_raw_configuration_and_restore(self):
        previous = [1, 2, 3, 4, 5, 6, [1] * 32]
        with patch('uart.os.open', return_value=91) as opened, \
             patch('uart.os.close') as closed, patch('uart.fcntl.flock') as lock, \
             patch('uart.termios.tcgetattr', side_effect=lambda fd: copy.deepcopy(previous)), \
             patch('uart.termios.tcsetattr') as settings, patch('uart.termios.tcflush'):
            port = SerialPort('fixture')
            opened.assert_called_once_with('fixture', os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
            lock.assert_called_once_with(91, fcntl.LOCK_EX | fcntl.LOCK_NB)
            configured = settings.call_args.args[2]
            self.assertEqual(configured[:6], [0, 0, termios.CLOCAL | termios.CREAD | termios.CS8,
                                              0, termios.B115200, termios.B115200])
            self.assertEqual(configured[6][termios.VMIN], 0)
            self.assertEqual(configured[6][termios.VTIME], 0)
            port.close()
            settings.assert_called_with(91, termios.TCSANOW, previous)
            port.close()
            closed.assert_called_once_with(91)

    def test_busy_port_is_closed_without_reconfiguring(self):
        with patch('uart.os.open', return_value=91), patch('uart.os.close') as closed, \
             patch('uart.fcntl.flock', side_effect=BlockingIOError), \
             patch('uart.termios.tcsetattr') as settings:
            with self.assertRaises(BlockingIOError):
                SerialPort('fixture')
            closed.assert_called_once_with(91)
            settings.assert_not_called()

    def test_flush_failure_restores_and_closes(self):
        previous = [1, 2, 3, 4, 5, 6, [1] * 32]
        with patch('uart.os.open', return_value=91), patch('uart.os.close') as closed, \
             patch('uart.fcntl.flock'), \
             patch('uart.termios.tcgetattr', side_effect=lambda fd: copy.deepcopy(previous)), \
             patch('uart.termios.tcsetattr') as settings, \
             patch('uart.termios.tcflush', side_effect=OSError('fixture')):
            with self.assertRaises(OSError):
                SerialPort('fixture')
            settings.assert_called_with(91, termios.TCSANOW, previous)
            closed.assert_called_once_with(91)

    def test_partial_writes_and_timeout(self):
        port = SerialPort.__new__(SerialPort)
        port.fd, port.write_timeout = 91, 1
        with patch('uart.select.select', return_value=([], [91], [])), \
             patch('uart.os.write', side_effect=[1, BlockingIOError(), 1]) as write:
            self.assertEqual(port.write(b'sv'), 2)
            self.assertEqual([bytes(c.args[1]) for c in write.call_args_list], [b'sv', b'v', b'v'])
        with patch('uart.select.select', return_value=([], [], [])):
            with self.assertRaises(TimeoutError):
                port.write(b'b')

    def test_read_timeout_and_disconnect(self):
        port = SerialPort.__new__(SerialPort)
        port.fd, port.timeout = 91, 0.2
        with patch('uart.select.select', return_value=([], [], [])), patch('uart.os.read') as read:
            self.assertEqual(port.read(4096), b'')
            read.assert_not_called()
        with patch('uart.select.select', return_value=([91], [], [])), patch('uart.os.read', return_value=b''):
            with self.assertRaisesRegex(OSError, 'disconnected'):
                port.read(4096)

    def test_pty_capture_commands_and_restore(self):
        master, slave = pty.openpty()
        previous = termios.tcgetattr(slave)
        port = None
        try:
            # Reuse a descriptor from our own PTY; never open a physical UART.
            with patch('uart.os.open', return_value=os.dup(slave)):
                port = SerialPort('fixture', timeout=0.02)
            self.assertEqual(port.read(4096), b'')
            os.write(master, b'S1RT,READY,continuous=1\r\n')
            self.assertEqual(port.read(4096), b'S1RT,READY,continuous=1\r\n')
            self.assertEqual(port.write(b'b'), 1)
            self.assertTrue(select.select([master], [], [], 1)[0])
            self.assertEqual(os.read(master, 16), b'b')
            port.close()
            self.assertEqual(termios.tcgetattr(slave), previous)
        finally:
            if port is not None:
                port.close()
            os.close(master)
            os.close(slave)


if __name__ == '__main__':
    unittest.main()
