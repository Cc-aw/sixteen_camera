"""Independent load semantics: original row/repeat writes, no window golden."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Load:
    address: int
    destination: int
    cols: int
    rows: int
    pixels: int
    stride: int
    zeros: bool = False


def source_rows(command, memory):
    return [bytes(command.cols) if command.zeros else
            bytes(memory(command.address + i * command.stride + j)
                  for j in range(command.cols)) for i in range(command.rows)]


def original_updates(command, samples, spad_rows=16384):
    """One masked write per original PixelRepeater repetition, in its order."""
    for i, sample in enumerate(samples):
        assert len(sample) == command.cols
        address = command.destination + i
        floor = 0 if address < spad_rows // 2 else spad_rows // 2
        for k in reversed(range(command.pixels)):
            target = address - k
            if target >= floor:
                yield target, k * command.cols, sample


def apply_updates(command, samples, initial, spad_rows=16384):
    result = {row: bytearray(data) for row, data in initial.items()}
    for row, start, data in original_updates(command, samples, spad_rows):
        result[row][start:start + len(data)] = data
    return result


def physical_reads(command, coalesced):
    """Address/length reference, without relying on RTL's planner output."""
    spans = ([(command.address, command.rows * command.cols)] if coalesced else
             [(command.address + i * command.stride, command.cols)
              for i in range(command.rows)])
    for address, count in spans:
        while count:
            candidates = [(min(count, width - address % width), width) for width in (32, 64)]
            useful, size = max(candidates, key=lambda item: (item[0], -item[1]))
            yield address // size * size, size, address, useful
            address += useful
            count -= useful
