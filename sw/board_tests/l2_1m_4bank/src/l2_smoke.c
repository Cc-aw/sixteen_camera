#include "board_io.h"

enum { BYTES = 2 * 1024 * 1024, WORDS = BYTES / 8, BLOCKS = 16, SLOTS = 32 };
static volatile uint64_t data[WORDS] __attribute__((aligned(131072)));
static uint64_t snapshot[BLOCKS][SLOTS];
static const unsigned bank_blocks[4] = {5, 6, 14, 15};
static const char *phase_names[] = {"fill", "stream_read", "byte_write_verify", "same_set_conflict"};

static uint64_t read64(unsigned off) {
    uint32_t low = board_read32(off), high = board_read32(off + 4);
    return low | ((uint64_t)high << 32);
}
static uint64_t ready(void) {
    uint64_t begin = board_cycles(), status;
    do {
        status = read64(0x10);
        if (!(status & 8) || (status & 16)) board_fail("statistics_unavailable", status);
        if (board_cycles() - begin > 10000000) board_fail("statistics_timeout", status);
    } while (status & 1);
    return status;
}
static uint64_t command(unsigned value) {
    (void)ready(); board_write32(8, value); return ready();
}
static void expected_reg(unsigned offset, uint64_t expected) {
    uint64_t actual = read64(offset);
    if (actual != expected) { board_field("L2BTEST,REGISTER_MISMATCH,offset=", offset); board_field(",expected=", expected); board_text("\n"); board_fail("hardware_geometry", actual); }
}
static void geometry(void) {
    expected_reg(0, UINT64_C(0x4d50563300010002));
    expected_reg(0x30, 0x3000); expected_reg(0x38, 1048576);
    expected_reg(0x40, 100000000); expected_reg(0x48, 300000000);
    expected_reg(0x50, 16); expected_reg(0x58, 4);
    expected_reg(0x60, 512); expected_reg(0x68, 32);
    if (ready() & 2) (void)command(2);
    board_text("L2BTEST,GEOMETRY,abi=1.2,banks=4,bytes=1048576,bank_mask=12288,blocks=16,data_bits=512,ordinary_mshrs=32,soc_hz=100000000,ddr_hz=300000000\n");
}
static uint64_t pattern(size_t index, unsigned pass) {
    /* Address-dependent data and distinct bytes catch tag/address aliasing. */
    uint64_t value = (uint64_t)(uintptr_t)&data[index] ^ (UINT64_C(0x9e3779b97f4a7c15) * (pass + 1));
    value ^= value >> 30; value *= UINT64_C(0xbf58476d1ce4e5b9);
    value ^= value >> 27; value *= UINT64_C(0x94d049bb133111eb);
    return value ^ (value >> 31);
}
static void check_word(size_t index, uint64_t expected) {
    uint64_t actual = data[index];
    if (actual != expected) {
        board_field("L2BTEST,DATA_MISMATCH,address=", (uintptr_t)&data[index]);
        board_field(",expected=", expected); board_field(",actual=", actual); board_text("\n");
        board_fail("memory_data", index);
    }
}
static uint64_t partial_expected(size_t index) {
    uint64_t value = pattern(index, 0);
    if (index % 8 == 0) value = (value & ~(UINT64_C(255) << 40)) | (UINT64_C(0xa5) << 40);
    if (index % 8 == 5) value = (value & ~(UINT64_C(255) << 56)) | (UINT64_C(0x3c) << 56);
    return value;
}
static void workload(unsigned phase) {
    if (phase == 0) {
        for (size_t i = 0; i < WORDS; i++) data[i] = pattern(i, 0);
    } else if (phase == 1) {
        for (size_t i = 0; i < WORDS; i++) check_word(i, pattern(i, 0));
    } else if (phase == 2) {
        volatile unsigned char *bytes = (volatile unsigned char *)data;
        for (size_t i = 0; i < BYTES; i += 64) { bytes[i + 5] = 0xa5; bytes[i + 47] = 0x3c; }
        board_fence();
        for (size_t i = WORDS; i-- > 0;) check_word(i, partial_expected(i));
    } else {
        /* 16 tags at a 128 KiB stride: one L2 set/bank, twice the 8 ways. */
        for (unsigned bank = 0; bank < 4; bank++) {
            for (unsigned tag = 0; tag < 16; tag++) {
                size_t first = ((size_t)tag * 131072 + bank * 4096) / 8;
                for (unsigned word = 0; word < 8; word++) data[first + word] = pattern(first + word, 1);
            }
            board_fence();
            for (unsigned tag = 16; tag-- > 0;) {
                size_t first = ((size_t)tag * 131072 + bank * 4096) / 8;
                for (unsigned word = 0; word < 8; word++) check_word(first + word, pattern(first + word, 1));
            }
        }
    }
}
static void capture(unsigned phase, uint64_t cycles, uint32_t sequence) {
    if (!(command(4) & 4) || (uint32_t)read64(0x18) != (uint32_t)(sequence + 1)) board_fail("snapshot_sequence", read64(0x18));
    for (unsigned block = 0; block < BLOCKS; block++) {
        for (unsigned slot = 0; slot < SLOTS; slot++) {
            unsigned index = block * SLOTS + slot;
            board_write32(0x20, index);
            if (board_read32(0x20) != index) board_fail("selector_readback", index);
            snapshot[block][slot] = read64(0x28);
        }
    }
    if ((ready() & 7) != 4 || (uint32_t)read64(0x18) != (uint32_t)(sequence + 1)) board_fail("snapshot_unstable", read64(0x10));
    board_field("L2BTEST,WINDOW,id=", phase); board_text(",name="); board_text(phase_names[phase]);
    board_field(",cycles=", cycles); board_field(",blocks=", BLOCKS); board_field(",sequence=", (uint32_t)(sequence + 1)); board_text("\n");
    for (unsigned block = 0; block < BLOCKS; block++) {
        board_field("L2BTEST,BLOCK,window=", phase); board_field(",id=", block);
        for (unsigned slot = 0; slot < SLOTS; slot++) {
            char key[] = {',','c',(char)('0' + slot / 10),(char)('0' + slot % 10),'=',0};
            board_field(key, snapshot[block][slot]);
        }
        board_text("\n");
    }
    for (unsigned bank = 0; bank < 4; bank++) {
        if (!snapshot[bank_blocks[bank]][1]) board_fail("bank_not_exercised", bank);
        const unsigned client_slots[4] = {11, 12, 14, 15};
        if (!snapshot[3][client_slots[bank]]) board_fail("cpu_bank_not_exercised", bank);
        if (snapshot[bank_blocks[bank]][11] > 32) board_fail("mshr_peak_out_of_range", bank);
    }
    board_field("L2BTEST,WINDOW_PASS,id=", phase); board_text(",banks_exercised=4,snapshot_stable=1\n");
}
int l2_smoke_run(void) {
    geometry();
    for (unsigned phase = 0; phase < 4; phase++) {
        if (command(3) & 6) board_fail("clear", phase);
        uint32_t sequence = (uint32_t)read64(0x18);
        if (!(command(1) & 2)) board_fail("start", phase);
        board_fence(); uint64_t begin = board_cycles();
        workload(phase); board_fence(); uint64_t cycles = board_cycles() - begin;
        if (command(2) & 2) board_fail("stop", phase);
        capture(phase, cycles, sequence);
    }
    board_text("L2BTEST,PASS,test=smoke,windows=4,buffer_bytes=2097152,banks_exercised=4,marker=ALL_SMOKE_COMPLETE\n");
    return 0;
}
