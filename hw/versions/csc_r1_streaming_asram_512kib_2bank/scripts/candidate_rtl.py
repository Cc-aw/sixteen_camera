#!/usr/bin/env python3
"""Reproducible experiment-local C1a overlay on the frozen generated C0.

No source in the parent generation context is modified. Each transformation
is guarded by the original file's recorded SHA and exact replacement counts.
This is a generated-RTL prototype, not a new production Scala/SoC export.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil

from full_command_rtl import closure, ports, FEATURE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def once(text, before, after):
    if text.count(before) != 1:
        raise ValueError('Overlay anchor changed: ' + before[:100])
    return text.replace(before, after, 1)


MONITOR_PORTS = '''
  input csc_enabled, csc_clear, csc_fault, csc_core_idle, csc_quiescent,
  input [7:0] csc_write_valid, csc_write_input,
  input [111:0] csc_write_rows,
  input csc_source_write,
  input [39:0] csc_source_write_address,
  input [6:0] csc_source_write_bytes,
  output csc_input_command,
  output [31:0] csc_engine_owner,
  output [63:0] csc_resident_owner,
'''


def prepare(context, out):
    identity = json.loads(context.read_text())
    original = context.parent / 'gen-collateral'
    files = closure(original, ('Gemmini',))
    for p in files:
        if sha(p) != identity['final_rtl_sha256'][p.name]:
            raise ValueError('Frozen RTL hash mismatch: ' + str(p))
    out.mkdir(parents=True, exist_ok=False)
    rtl = out / 'gen-collateral'
    rtl.mkdir()
    for p in files:
        shutil.copyfile(p, rtl / p.name)

    lc_path = rtl / 'LoopConv.sv'
    lc = lc_path.read_text()
    lc = once(lc, 'module LoopConv(', 'module LoopConv(' + MONITOR_PORTS)
    # Extract the exact effective Input generator fields after slot and
    # a_ex_spad_id selection. Output-channel/weight geometry is not an Input key.
    instance = re.search(r'  LoopConvLdInput ld_input \(.*?\n  \);', lc, re.S)[0]
    fields = {}
    widths = {n: w.strip() for d, w, n in ports(rtl / 'LoopConvLdInput.sv') if d == 'input'}
    extra = []
    for line in instance.splitlines():
        m = re.match(r'\s*\.(io_req_bits_\w+)\s+\((.*?)\),?(?:\s*//.*)?$', line)
        if not m:
            continue
        name, expression = m.groups()
        wire = 'csc_' + name[len('io_req_bits_'):]
        fields[name[len('io_req_bits_'):]] = wire
        extra.append(f'  wire {widths[name]} {wire} = {expression};')
    required = ['outer_bounds_in_col_dim', 'outer_bounds_in_stride',
                'inner_bounds_lpad', 'inner_bounds_rpad', 'inner_bounds_upad', 'inner_bounds_dpad',
                'derived_params_irows', 'derived_params_icols', 'derived_params_irows_unpadded',
                'derived_params_icols_unpadded', 'derived_params_ichs', 'derived_params_input_spad_stride']
    assert len(fields) == 22, fields
    extra += [
        '  wire csc_engine_ready, csc_hit, csc_wait, csc_accepted, csc_skipped, csc_completion;',
        '  wire [1:0] csc_resident_valid, csc_resident_building;',
        "  assign csc_input_command = _ld_input_io_cmd_valid && _arb_io_in_4_ready && _ld_input_io_cmd_bits_inst_funct == 7'd2;",
        '  wire [231:0] csc_key = {' + ', '.join(fields[x] for x in required) + ', csc_dram_addr};',
        '  wire [63:0] csc_row_count = (({48\'d0,csc_derived_params_ichs} + 31) >> 5) * {48\'d0,csc_derived_params_input_spad_stride};',
        '  wire [63:0] csc_source_span = (({48\'d0,csc_derived_params_irows_unpadded} - 1) * {48\'d0,csc_outer_bounds_in_col_dim} + {48\'d0,csc_derived_params_icols_unpadded} - 1) * {48\'d0,csc_outer_bounds_in_stride} + {48\'d0,csc_derived_params_ichs};',
        '  wire [63:0] csc_source_end_full = {24\'d0,csc_dram_addr} + csc_source_span;',
        '''  wire csc_supported_geometry = !csc_downsample && !csc_input_dilated && !csc_trans_input_3120 &&
    csc_max_pixels_per_row == 1 && csc_inner_bounds_batches == 1 && csc_dram_addr != 0 &&
    csc_derived_params_irows_unpadded != 0 && csc_derived_params_icols_unpadded != 0 &&
    csc_derived_params_ichs != 0 && csc_outer_bounds_in_stride >= csc_derived_params_ichs &&
    {48'd0,csc_derived_params_input_spad_stride} == {48'd0,csc_derived_params_irows} * {48'd0,csc_derived_params_icols} &&
    {48'd0,csc_derived_params_irows} == {48'd0,csc_derived_params_irows_unpadded} + {48'd0,csc_inner_bounds_upad} + {48'd0,csc_inner_bounds_dpad} &&
    {48'd0,csc_derived_params_icols} == {48'd0,csc_derived_params_icols_unpadded} + {48'd0,csc_inner_bounds_lpad} + {48'd0,csc_inner_bounds_rpad} &&
    csc_row_count > 0 && csc_row_count <= 8192 && csc_source_span < 64'h100000000 &&
    csc_source_end_full <= 64'h200000000;''',
        '''  CscR1InputResidency csc_residency (
    .clock(clock), .reset(reset), .enabled(csc_enabled), .clear(csc_clear), .fault(csc_fault),
    .core_idle(csc_core_idle),
    .quiescent(csc_quiescent && ld_utilization == 0 && st_utilization == 0 &&
      _ld_weights_io_idle && _ld_bias_io_idle &&
      !ld_weights_io_req_valid && !ld_bias_io_req_valid),
    .passthrough(io_out_valid && io_out_ready && !io_out_bits_from_conv_fsm &&
      io_out_bits_cmd_inst_funct != 0 && io_out_bits_cmd_inst_funct != 26),
    .req_valid(ld_input_io_req_valid), .engine_ready(csc_engine_ready),
    .req_supported(csc_supported), .req_preserves(csc_dram_addr == 0),
    .req_half(csc_addr_start[13]), .req_key(csc_key),
    .req_rows(csc_row_count[14:0]), .req_source(csc_dram_addr), .req_source_end(csc_source_end_full[40:0]),
    .generator_idle(_ld_input_io_idle), .generator_half(ld_input.req_addr_start[13]),
    .write_valid(csc_write_valid), .write_input(csc_write_input), .write_rows(csc_write_rows),
    .source_write(csc_source_write), .source_write_address(csc_source_write_address),
    .source_write_bytes(csc_source_write_bytes),
    .req_ready(_ld_input_io_req_ready), .hit(csc_hit), .wait_for_commit(csc_wait),
    .accepted(csc_accepted), .skipped(csc_skipped), .completion(csc_completion),
    .resident_valid(csc_resident_valid), .resident_building(csc_resident_building),
    .resident_owner(csc_resident_owner), .engine_owner(csc_engine_owner)
  );'''
    ]
    # A Store waiting for EX is not an issued memory transaction. Prove its
    # complete output envelope disjoint instead of waiting for all EX/Store
    # generation to finish. Cover BOTH configured slots (including overrides
    # and not-yet-derived slots) plus the independent latched Store generator;
    # a slot may already have been recycled while that generator drains.
    for s in range(3):
        prefix = f'loops_{s}_' if s < 2 else 'st.req_'
        active = (f'(loops_{s}_configured || loops_{s}_derive_pending || loops_{s}_deriving)'
                  if s < 2 else '!_st_io_idle')
        # A run/derive-pending slot already owns all native configuration
        # words. Its derived ochs may still be stale: use the full outer
        # output-channel count as a conservative bound instead.
        known = active if s < 2 else "1'b1"
        def field(name):
            return prefix + name
        extra += [f'  wire csc_store_disjoint_{s};', f'''  CscR1StoreDisjoint csc_store_range_{s} (
    .active({active}), .known({known}),
    .no_pool({field('no_pool')}), .transpose({field('trans_output_1203')}),
    .batches({field('inner_bounds_batches')}),
    .rows({field('inner_bounds_orows')}), .cols({field('inner_bounds_ocols')}),
    .outer_cols({field('outer_bounds_out_col_dim')}), .stride({field('outer_bounds_out_stride')}),
    .channels({field('outer_bounds_out_channels') if s < 2 else field('derived_params_ochs')}),
    .base({field('output_dram_addr') if s < 2 else field('dram_addr')}),
    .source(csc_dram_addr), .source_end(csc_source_end_full[40:0]),
    .disjoint(csc_store_disjoint_{s})
  );''']
    extra += ['  wire csc_supported = csc_supported_geometry && csc_store_disjoint_0 && csc_store_disjoint_1 && csc_store_disjoint_2;']
    old_instance = re.search(r'  LoopConvLdInput ld_input \(.*?\n  \);', lc, re.S)[0]
    instance = once(instance, '(_ld_input_io_req_ready)', '(csc_engine_ready)')
    instance = once(instance, '(ld_input_io_req_valid)', '(ld_input_io_req_valid && !csc_wait)')
    instance = once(instance, 'LoopConvLdInput ld_input (', 'LoopConvLdInput ld_input (\n    .csc_skip(csc_hit),')
    lc = once(lc, old_instance, '\n'.join(extra) + '\n' + instance)
    lc_path.write_text(lc)

    # Preserve the original Input CONFIG command on a hit. Skipping this state
    # update would leave raw subsequent Mvin commands observing a stale scale,
    # stride or pixel-repeat configuration. Only the whole Mvin sequence is cut.
    input_path = rtl / 'LoopConvLdInput.sv'
    inp = once(input_path.read_text(), 'module LoopConvLdInput(', 'module LoopConvLdInput(\n  input csc_skip,\n')
    inp = once(inp, '  wire        spatial_p_io_in_valid = ', '''  reg csc_skip_reg;
  always @(posedge clock) begin
    if (reset) csc_skip_reg <= 0;
    else if (io_req_ready_0 && io_req_valid) csc_skip_reg <= csc_skip;
  end
  wire        spatial_p_io_in_valid = (!csc_skip_reg || state == 2'h1) & ''')
    inp = once(inp, "state <= spatial_p_io_in_bits_is_config ? 2'h2 :",
               "state <= spatial_p_io_in_bits_is_config ? (csc_skip_reg ? 2'h0 : 2'h2) :")
    input_path.write_text(inp)

    # Expose physical write acceptance, with original writer tag. Classification
    # is captured at acceptance, before tag recycling; no tag is re-read at commit.
    sp_path = rtl / 'Scratchpad.sv'
    sp = sp_path.read_text()
    sp = once(sp, 'module Scratchpad(', '''module Scratchpad(
  output [7:0] csc_write_valid, csc_write_ex,
  output [63:0] csc_write_tags,
  output [111:0] csc_write_rows,
  output csc_bank_pending,
''')
    sp_extra, pending = [], []
    for b in range(8):
        q = 'pending' if b == 0 else f'pending_{b}'
        sel = 'selected' if b == 0 else f'selected_{b}'
        sp_extra += [f'  assign csc_write_valid[{b}] = {q}.io_enq_valid && {q}.io_enq_ready;',
                     f'  assign csc_write_ex[{b}] = {q}.io_enq_bits_ex;',
                     f'  assign csc_write_rows[{b*14}+:14] = {{3\'d{b}, {q}.io_enq_bits_addr}};',
                     f'  assign csc_write_tags[{b*8}+:8] = {sel} == 2 ? _zeroWriteBuffer_io_deq_bits_tag_cmd_id : _mvinWriteBuffer_io_deq_bits_tag_cmd_id;']
        pending.append(q + '.io_deq_valid')
    sp_extra.append('  assign csc_bank_pending = ' + ' | '.join(pending) + ';')
    sp = once(sp, 'endmodule', '\n'.join(sp_extra) + '\nendmodule')
    sp_path.write_text(sp)

    ld_path = rtl / 'LoadController.sv'
    ld = once(ld_path.read_text(), 'module LoadController(', 'module LoadController(\n  output csc_row_input,\n')
    ld = once(ld, 'endmodule', "  assign csc_row_input = _cmd_q_io_deq_bits_cmd_inst_funct == 7'd2;\nendmodule")
    ld_path.write_text(ld)

    gm_path = rtl / 'Gemmini.sv'
    gm = once(gm_path.read_text(), 'module Gemmini(', 'module Gemmini(\n  input csc_enabled,\n  input csc_clear,\n')
    wires = '''
  wire [7:0] csc_write_valid, csc_write_ex, csc_write_input;
  wire [63:0] csc_write_tags;
  wire [111:0] csc_write_rows;
  wire csc_bank_pending, csc_row_input;
  reg [1:0] csc_previous_mode;
  always @(posedge clock) csc_previous_mode <= reset ? 2'd0 : io_dma_load_mode;
  wire csc_input_command;
  wire [31:0] csc_engine_owner;
  wire [63:0] csc_resident_owner;
  // Only ownership metadata is buffered. Commands/data/credits retain C0 paths.
  reg [31:0] csc_owner_fifo [0:31];
  reg [4:0] csc_owner_head, csc_owner_tail;
  reg [5:0] csc_owner_count;
  wire csc_ld_issue = _reservation_station_io_issue_ld_valid && _load_controller_io_cmd_ready;
  wire csc_is_load = _reservation_station_io_issue_ld_cmd_cmd_inst_funct == 2 ||
    _reservation_station_io_issue_ld_cmd_cmd_inst_funct == 1 ||
    _reservation_station_io_issue_ld_cmd_cmd_inst_funct == 14;
  wire csc_owner_pop = csc_ld_issue && _reservation_station_io_issue_ld_cmd_from_conv_fsm &&
    _reservation_station_io_issue_ld_cmd_cmd_inst_funct == 2;
  reg [31:0] csc_load_fifo [0:31];
  reg [4:0] csc_load_head, csc_load_tail;
  reg [5:0] csc_load_count;
  wire csc_load_push = csc_ld_issue && csc_is_load;
  wire csc_load_pop = _load_controller_io_dma_req_valid && _spad_io_dma_read_req_ready &&
    _load_controller_io_dma_req_bits_cmd_first;
  reg [31:0] csc_tag_owner [0:1];
  always @(posedge clock) begin
    if (reset) begin
      csc_owner_head <= 0; csc_owner_tail <= 0; csc_owner_count <= 0;
      csc_load_head <= 0; csc_load_tail <= 0; csc_load_count <= 0;
      csc_tag_owner[0] <= 0; csc_tag_owner[1] <= 0;
    end else begin
      case ({csc_input_command,csc_owner_pop})
        2'b10: csc_owner_count <= csc_owner_count + 1;
        2'b01: csc_owner_count <= csc_owner_count - 1;
        default: ;
      endcase
      if (csc_input_command) begin
        csc_owner_fifo[csc_owner_tail] <= csc_engine_owner;
        csc_owner_tail <= csc_owner_tail + 1;
      end
      if (csc_owner_pop) csc_owner_head <= csc_owner_head + 1;
      case ({csc_load_push,csc_load_pop})
        2'b10: csc_load_count <= csc_load_count + 1;
        2'b01: csc_load_count <= csc_load_count - 1;
        default: ;
      endcase
      if (csc_load_push) begin
        csc_load_fifo[csc_load_tail] <= csc_owner_pop ? csc_owner_fifo[csc_owner_head] : 0;
        csc_load_tail <= csc_load_tail + 1;
      end
      if (csc_load_pop) begin
        csc_tag_owner[_load_controller_io_dma_req_bits_cmd_id[0]] <= csc_load_fifo[csc_load_head];
        csc_load_head <= csc_load_head + 1;
      end
    end
  end
  for (genvar csc_b = 0; csc_b < 8; csc_b = csc_b + 1) begin
    wire [31:0] owner = (csc_load_pop &&
        _load_controller_io_dma_req_bits_cmd_id == csc_write_tags[csc_b*8+:8]) ?
       csc_load_fifo[csc_load_head] : csc_tag_owner[csc_write_tags[csc_b*8]];
    assign csc_write_input[csc_b] = !csc_write_ex[csc_b] && owner != 0 &&
      owner == (csc_write_rows[csc_b*14+13] ? csc_resident_owner[63:32] : csc_resident_owner[31:0]);
  end
`ifndef SYNTHESIS
  always @(posedge clock) if (!reset) begin
    assert (!csc_owner_pop || csc_owner_count != 0) else $fatal(1,"CSC input owner underflow");
    assert (!csc_input_command || csc_owner_count < 32 || csc_owner_pop) else $fatal(1,"CSC input owner overflow");
    assert (!csc_load_pop || csc_load_count != 0) else $fatal(1,"CSC load owner underflow");
    assert (!csc_load_push || csc_load_count < 32 || csc_load_pop) else $fatal(1,"CSC load owner overflow");
    assert (!csc_load_pop || _load_controller_io_dma_req_bits_cmd_id < 2) else $fatal(1,"CSC unexpected DMA tag");
    for (integer cb=0; cb<8; cb=cb+1)
      assert (!csc_write_valid[cb] || csc_write_ex[cb] || csc_write_tags[cb*8+:8] < 2)
        else $fatal(1,"CSC unexpected write tag");
  end
`endif
'''
    gm = once(gm, '  LoopConv mod (', wires + '\n  LoopConv mod (' + '''
    .csc_enabled(csc_enabled), .csc_clear(csc_clear || csc_previous_mode != io_dma_load_mode),
    .csc_fault(io_interrupt || (auto_spad_id_out_d_valid && auto_spad_id_out_d_ready &&
      (auto_spad_id_out_d_bits_denied || auto_spad_id_out_d_bits_corrupt))),
    .csc_core_idle(!busyReg),
    .csc_quiescent(!_spad_io_busy && !_load_controller_io_busy && !_store_controller_io_busy && !csc_bank_pending),
    .csc_write_valid(csc_write_valid), .csc_write_input(csc_write_input), .csc_write_rows(csc_write_rows),
    .csc_input_command(csc_input_command), .csc_engine_owner(csc_engine_owner), .csc_resident_owner(csc_resident_owner),
    .csc_source_write(auto_spad_id_out_a_valid && auto_spad_id_out_a_ready && auto_spad_id_out_a_bits_opcode <= 1),
    .csc_source_write_address({7'd0,auto_spad_id_out_a_bits_address}),
    .csc_source_write_bytes(7'd1 << auto_spad_id_out_a_bits_size),
''')
    gm = once(gm, '  Scratchpad spad (', '''  Scratchpad spad (
    .csc_write_valid(csc_write_valid), .csc_write_ex(csc_write_ex),
    .csc_write_rows(csc_write_rows), .csc_write_tags(csc_write_tags), .csc_bank_pending(csc_bank_pending),''')
    gm = once(gm, '  LoadController load_controller (', '  LoadController load_controller (\n    .csc_row_input(csc_row_input),')
    gm_path.write_text(gm)
    module = FEATURE / 'rtl/CscR1InputResidency.sv'
    shutil.copyfile(module, rtl / module.name)
    store_module = FEATURE / 'rtl/CscR1StoreDisjoint.sv'
    shutil.copyfile(store_module, rtl / store_module.name)
    # Keep the original identity, replacing only independently recorded file SHAs.
    result = dict(schema=1, status='EXPERIMENTAL_C1A_GENERATED_RTL_OVERLAY',
                  production_export=False, parent_context=str(context), parent_context_sha256=sha(context),
                  parent_build_id=identity['dma_load_build_id'],
                  overlay_sources_sha256={str(p): sha(p) for p in (Path(__file__).resolve(), module, store_module)},
                  parent_rtl_sha256={str(p): sha(p) for p in files},
                  final_rtl_sha256={p.name: sha(p) for p in rtl.iterdir()})
    (out / 'CANDIDATE_CONTEXT.json').write_text(json.dumps(result, indent=2) + '\n')
    print('CSC_R1_CANDIDATE_PREPARED', out)
    return out / 'CANDIDATE_CONTEXT.json'


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--context', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.context.resolve(), args.output.resolve())
