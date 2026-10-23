`timescale 1ns/1ps

// Tensor production commands, indexed descriptors and DMA telemetry.
module tensor_csr #(
    parameter integer CHANNELS = 16,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1}
) (
    input  wire clk,
    input  wire resetn,
    input  wire write_valid,
    input  wire [9:0] write_addr,
    input  wire [31:0] write_data,
    input  wire [3:0] write_strb,
    input  wire [9:0] read_addr,
    output reg  read_hit,
    output reg  [31:0] read_data,
    output reg  tensor_production_enable,
    output reg  [15:0] tensor_production_admission_mask,
    output reg  [4:0] tensor_production_admission_limit,
    output reg  tensor_production_release_toggle,
    output reg  [31:0] tensor_production_release_mask,
    input  wire tensor_production_release_ack,
    input  wire [31:0] tensor_production_ready_mask,
    input  wire [31:0] tensor_production_writing_mask,
    input  wire [31:0] tensor_production_error_mask,
    input  wire [32*32-1:0] tensor_production_frame_ids,
    input  wire [32*64-1:0] tensor_production_timestamps,
    input  wire [32*32-1:0] tensor_production_versions,
    input  wire [32*8-1:0] tensor_production_error_codes,
    input  wire [32*32-1:0] tensor_production_byte_counts,
    input  wire [16*32-1:0] tensor_production_no_slot_counts,
    input  wire [16*32-1:0] tensor_production_missed_counts,
    input  wire [16*32-1:0] tensor_production_admission_skip_counts,
    input  wire [16*32-1:0] tensor_production_overflow_counts,
    input  wire [15:0] tensor_dma_outstanding_current,
    input  wire [15:0] tensor_dma_outstanding_max,
    input  wire [31:0] tensor_dma_source_starvation,
    input  wire [31:0] tensor_dma_aw_stall_cycles,
    input  wire [31:0] tensor_dma_w_stall_cycles,
    input  wire [31:0] tensor_dma_w_transfer_cycles,
    input  wire [31:0] tensor_dma_b_wait_cycles,
    input  wire [31:0] tensor_dma_bursts_issued,
    input  wire [31:0] tensor_dma_bursts_completed,
    input  wire [31:0] tensor_dma_response_errors
);
    localparam [9:0] REG_CONTROL = 10'h2d0;
    localparam [9:0] REG_RELEASE = 10'h2d4;
    localparam [9:0] REG_READY = 10'h2d8;
    localparam [9:0] REG_WRITING = 10'h2dc;
    localparam [9:0] REG_ERROR = 10'h2e0;
    localparam [9:0] REG_INDEX = 10'h2e4;
    localparam [9:0] REG_FRAME = 10'h2e8;
    localparam [9:0] REG_BYTES = 10'h2ec;
    localparam [9:0] REG_NO_SLOT = 10'h2f0;
    localparam [9:0] REG_OVERFLOW = 10'h2f4;
    localparam [9:0] REG_MISSED = 10'h2f8;
    localparam [9:0] REG_DMA_OUTSTANDING = 10'h300;
    localparam [9:0] REG_DMA_OUTSTANDING_MAX = 10'h304;
    localparam [9:0] REG_DMA_STARVATION = 10'h308;
    localparam [9:0] REG_DMA_AW_STALL = 10'h30c;
    localparam [9:0] REG_DMA_W_STALL = 10'h310;
    localparam [9:0] REG_DMA_W_TRANSFER = 10'h314;
    localparam [9:0] REG_DMA_B_WAIT = 10'h318;
    localparam [9:0] REG_DMA_BURSTS = 10'h31c;
    localparam [9:0] REG_DMA_COMPLETED = 10'h320;
    localparam [9:0] REG_DMA_RESP_ERRORS = 10'h324;
    localparam [9:0] REG_TIME_LO = 10'h328;
    localparam [9:0] REG_TIME_HI = 10'h32c;
    localparam [9:0] REG_VERSION = 10'h330;
    localparam [9:0] REG_STREAM = 10'h334;
    localparam [9:0] REG_ADDR = 10'h338;
    localparam [9:0] REG_STATE = 10'h33c;
    localparam [9:0] REG_ERROR_CODE = 10'h340;
    localparam [9:0] REG_ADMISSION_MASK = 10'h344;
    localparam [9:0] REG_ADMISSION_LIMIT = 10'h348;
    localparam [9:0] REG_ADMISSION_SKIP = 10'h34c;
    localparam [31:0] TENSOR_ARENA0_BASE = 32'h3000_0000;
    localparam [31:0] TENSOR_ARENA1_BASE = 32'h3100_0000;
    localparam [31:0] TENSOR_MEMBER_STRIDE = 32'h000e_1000;

    reg [4:0] tensor_production_index;
    wire release_busy = tensor_production_release_toggle !=
                        tensor_production_release_ack;

    function automatic [31:0] apply_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0] strb;
        integer byte_index;
        begin
            apply_wstrb = old_value;
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                if (strb[byte_index])
                    apply_wstrb[byte_index*8 +: 8] =
                        new_value[byte_index*8 +: 8];
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            tensor_production_enable <= 1'b0;
            tensor_production_admission_mask <= CAMERA_PRESENT_MASK;
            tensor_production_admission_limit <= 5'd1;
            tensor_production_release_toggle <= 1'b0;
            tensor_production_release_mask <= 32'd0;
            tensor_production_index <= 5'd0;
        end else if (write_valid) begin
            case (write_addr)
                REG_CONTROL: if (write_strb[0]) begin
                    tensor_production_enable <= write_data[0];
                    if (write_data[1] && !release_busy)
                        tensor_production_release_toggle <=
                            !tensor_production_release_toggle;
                end
                REG_RELEASE: if (!release_busy)
                    tensor_production_release_mask <= apply_wstrb(
                        tensor_production_release_mask, write_data, write_strb);
                REG_INDEX: if (write_strb[0] && write_data < 32)
                    tensor_production_index <= write_data[4:0];
                REG_ADMISSION_MASK: if (!tensor_production_enable) begin
                    if (write_strb[0])
                        tensor_production_admission_mask[7:0] <= write_data[7:0];
                    if (write_strb[1])
                        tensor_production_admission_mask[15:8] <=
                            write_data[15:8];
                end
                REG_ADMISSION_LIMIT:
                    if (!tensor_production_enable && write_strb[0] &&
                        write_data >= 1 && write_data <= CHANNELS)
                        tensor_production_admission_limit <= write_data[4:0];
                default: begin end
            endcase
        end
    end

    always @* begin
        read_hit = 1'b1;
        case (read_addr)
            REG_CONTROL: read_data = {30'd0, release_busy,
                                      tensor_production_enable};
            REG_RELEASE: read_data = tensor_production_release_mask;
            REG_READY: read_data = tensor_production_ready_mask;
            REG_WRITING: read_data = tensor_production_writing_mask;
            REG_ERROR: read_data = tensor_production_error_mask;
            REG_INDEX: read_data = {27'd0, tensor_production_index};
            REG_FRAME: read_data = tensor_production_frame_ids[
                tensor_production_index*32 +: 32];
            REG_BYTES: read_data = tensor_production_byte_counts[
                tensor_production_index*32 +: 32];
            REG_NO_SLOT: read_data = tensor_production_no_slot_counts[
                tensor_production_index[3:0]*32 +: 32];
            REG_OVERFLOW: read_data = tensor_production_overflow_counts[
                tensor_production_index[3:0]*32 +: 32];
            REG_MISSED: read_data = tensor_production_missed_counts[
                tensor_production_index[3:0]*32 +: 32];
            REG_DMA_OUTSTANDING:
                read_data = {16'd0, tensor_dma_outstanding_current};
            REG_DMA_OUTSTANDING_MAX:
                read_data = {16'd0, tensor_dma_outstanding_max};
            REG_DMA_STARVATION: read_data = tensor_dma_source_starvation;
            REG_DMA_AW_STALL: read_data = tensor_dma_aw_stall_cycles;
            REG_DMA_W_STALL: read_data = tensor_dma_w_stall_cycles;
            REG_DMA_W_TRANSFER: read_data = tensor_dma_w_transfer_cycles;
            REG_DMA_B_WAIT: read_data = tensor_dma_b_wait_cycles;
            REG_DMA_BURSTS: read_data = tensor_dma_bursts_issued;
            REG_DMA_COMPLETED: read_data = tensor_dma_bursts_completed;
            REG_DMA_RESP_ERRORS: read_data = tensor_dma_response_errors;
            REG_TIME_LO: read_data = tensor_production_timestamps[
                tensor_production_index*64 +: 32];
            REG_TIME_HI: read_data = tensor_production_timestamps[
                tensor_production_index*64 + 32 +: 32];
            REG_VERSION: read_data = tensor_production_versions[
                tensor_production_index*32 +: 32];
            REG_STREAM: read_data = {28'd0, tensor_production_index[3:0]};
            REG_ADDR: read_data = (tensor_production_index[4] ?
                TENSOR_ARENA1_BASE : TENSOR_ARENA0_BASE) +
                tensor_production_index[3:0] * TENSOR_MEMBER_STRIDE;
            REG_STATE:
                if (tensor_production_error_mask[tensor_production_index])
                    read_data = 32'd4;
                else if (tensor_production_writing_mask[
                             tensor_production_index])
                    read_data = 32'd1;
                else if (tensor_production_ready_mask[
                             tensor_production_index])
                    read_data = 32'd2;
                else
                    read_data = 32'd0;
            REG_ERROR_CODE: read_data = {24'd0,
                tensor_production_error_codes[
                    tensor_production_index*8 +: 8]};
            REG_ADMISSION_MASK:
                read_data = {16'd0, tensor_production_admission_mask};
            REG_ADMISSION_LIMIT:
                read_data = {27'd0, tensor_production_admission_limit};
            REG_ADMISSION_SKIP:
                read_data = tensor_production_admission_skip_counts[
                    tensor_production_index[3:0]*32 +: 32];
            default: begin
                read_hit = 1'b0;
                read_data = 32'd0;
            end
        endcase
    end
endmodule
