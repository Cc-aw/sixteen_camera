"""Geometry shared by generated-RTL checks and software cache-layout analysis."""
from dataclasses import asdict, dataclass
import json
from pathlib import Path


@dataclass(frozen=True)
class L2Geometry:
    banks: int
    sets_per_bank: int = 512
    ways: int = 8
    line_bytes: int = 64

    def __post_init__(self):
        if (self.banks not in (2, 4) or self.sets_per_bank != 512 or
                self.ways != 8 or self.line_bytes != 64):
            raise ValueError("Supported S1 L2 profiles are 2/4 banks of 256 KiB")

    @property
    def bank_mask(self):
        return (self.banks - 1) << 12

    @property
    def set_address_bits(self):
        return [bit for bit in range(6, 17) if not self.bank_mask & (1 << bit)][:9]

    @property
    def capacity_bytes(self):
        return self.banks * self.sets_per_bank * self.ways * self.line_bytes

    @property
    def period_bytes(self):
        return 1 << (max(self.set_address_bits) + 1)

    @property
    def colors(self):
        return self.period_bytes // self.line_bytes

    @property
    def statistics_abi(self):
        return "1.2" if self.banks == 4 else "1.1"

    @property
    def statistics_blocks(self):
        return 16 if self.banks == 4 else 14

    def bank(self, address):
        return (address & self.bank_mask) >> 12

    def set_index(self, address):
        return sum(((address >> bit) & 1) << index
                   for index, bit in enumerate(self.set_address_bits))

    def describe(self):
        return dict(asdict(self), bank_mask=self.bank_mask,
                    set_address_bits=self.set_address_bits,
                    capacity_bytes=self.capacity_bytes, period_bytes=self.period_bytes,
                    statistics_abi=self.statistics_abi)

    @classmethod
    def from_metadata(cls, path):
        banks = json.loads(Path(path).read_text())["banks"]
        geometry = cls(len(banks))
        for index, bank in enumerate(banks):
            assert bank["ways"] == geometry.ways and bank["blockBytes"] == geometry.line_bytes
            assert bank["setBits"] == geometry.set_address_bits
            assert all(entry["mask"] & geometry.bank_mask == 0 and
                       geometry.bank(entry["base"]) == index for entry in bank["addresses"])
        return geometry


def current_geometry(root):
    product = json.loads((Path(root) / "hw/manifests/current.json").read_text())
    metadata = list((Path(root) / product["soc_directory"]).glob("*.l2.json"))
    if len(metadata) != 1:
        raise ValueError("One complete generated L2 metadata file is required")
    geometry = L2Geometry.from_metadata(metadata[0])
    for key, expected in product.get("l2", {}).items():
        if key in geometry.describe():
            assert geometry.describe()[key] == expected, "Manifest and generated L2 disagree: " + key
    return geometry
