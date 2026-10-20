#!/usr/bin/env python3
"""POSIX UART capture using the same standard-library APIs as S1 board tests."""
import fcntl
import os
import select
import termios
import time


class SerialPort:
    """Exclusive 115200 8N1 port; restore terminal settings on close."""

    def __init__(self, path, baudrate=115200, timeout=0.2, write_timeout=2):
        if baudrate != 115200:
            raise ValueError('S1 UART requires 115200 baud')
        self.timeout = timeout
        self.write_timeout = write_timeout
        self.fd = None
        self.previous = None
        self.configured = False
        self.fd = os.open(path, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        try:
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.previous = termios.tcgetattr(self.fd)
            settings = termios.tcgetattr(self.fd)
            settings[0] = settings[1] = settings[3] = 0
            settings[2] = termios.CLOCAL | termios.CREAD | termios.CS8
            settings[4] = settings[5] = termios.B115200
            settings[6][termios.VMIN] = settings[6][termios.VTIME] = 0
            termios.tcsetattr(self.fd, termios.TCSANOW, settings)
            self.configured = True
            termios.tcflush(self.fd, termios.TCIFLUSH)
        except BaseException:
            self.close()
            raise

    def read(self, size):
        if not select.select([self.fd], [], [], self.timeout)[0]:
            return b''
        try:
            data = os.read(self.fd, size)
        except BlockingIOError:
            return b''
        if not data:
            raise OSError('UART disconnected')
        return data

    def write(self, data):
        pending = memoryview(data)
        deadline = time.monotonic() + self.write_timeout
        while pending:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not select.select([], [self.fd], [], remaining)[1]:
                raise TimeoutError('UART write timed out')
            try:
                count = os.write(self.fd, pending)
            except BlockingIOError:
                continue
            if count <= 0:
                raise OSError('UART disconnected during write')
            pending = pending[count:]
        return len(data)

    def close(self):
        if self.fd is None:
            return
        fd, self.fd = self.fd, None
        try:
            if self.configured:
                termios.tcsetattr(fd, termios.TCSANOW, self.previous)
        finally:
            os.close(fd)
