`timescale 1ns/1ps

// DDR UI clock-domain frame-buffer ownership manager.  The current display
// frame remains owned and is repeated until a newer complete frame is ready.
module frame_buffer_manager #(
    parameter integer MAX_BUFFERS = 4
) (
    input  wire                         ui_clk,
    input  wire                         ui_resetn,
    input  wire                         cfg_request_toggle,
    output reg                          cfg_ack_toggle,
    input  wire                         cfg_enable,
    input  wire [31:0]                  cfg_width,
    input  wire [31:0]                  cfg_height,
    input  wire [31:0]                  cfg_stride_bytes,
    input  wire [31:0]                  cfg_buffer_count,
    input  wire [MAX_BUFFERS*32-1:0]    cfg_buffer_bases,

    input  wire                         writer_acquire,
    output reg                          writer_grant,
    output reg                          writer_drop,
    output reg [31:0]                   writer_base,
    input  wire                         writer_done,
    input  wire                         writer_error,
    input  wire                         reader_acquire,
    output reg                          reader_grant,
    output reg [31:0]                   reader_base,
    input  wire                         reader_done,
    input  wire                         reader_underflow,

    output reg [31:0]                   active_width,
    output reg [31:0]                   active_height,
    output reg [31:0]                   active_stride_bytes,
    output reg [31:0]                   writer_frame_count,
    output reg [31:0]                   reader_frame_count,
    output reg [31:0]                   drop_count,
    output reg [31:0]                   underflow_count,
    output reg [31:0]                   status
);
    localparam integer INDEX_WIDTH = (MAX_BUFFERS <= 1) ? 1 : $clog2(MAX_BUFFERS);
    localparam [1:0] BUFFER_FREE    = 2'd0;
    localparam [1:0] BUFFER_WRITING = 2'd1;
    localparam [1:0] BUFFER_READY   = 2'd2;
    localparam [1:0] BUFFER_READING = 2'd3;

    (* ASYNC_REG = "TRUE" *) reg cfg_sync_1;
    (* ASYNC_REG = "TRUE" *) reg cfg_sync_2;
    reg [31:0] active_bases [0:MAX_BUFFERS-1];
    reg [1:0] buffer_state [0:MAX_BUFFERS-1];
    // Record the newest completed buffer when the writer finishes.  Keeping
    // the answer as an index avoids a four-way 32-bit sequence comparison on
    // every reader request, which is too deep for the 300 MHz DDR UI clock.
    reg latest_ready_valid;
    reg [INDEX_WIDTH-1:0] latest_ready_index;
    reg [2:0] active_buffer_count;
    reg writer_active;
    reg reader_active;
    reg [INDEX_WIDTH-1:0] writer_index;
    reg [INDEX_WIDTH-1:0] reader_index;
    reg drop_reported;
    integer i;
    integer status_i;

    function automatic integer find_free;
        integer index;
        begin
            find_free = -1;
            for (index = 0; index < MAX_BUFFERS; index = index + 1)
                if ((index < active_buffer_count) &&
                    (buffer_state[index] == BUFFER_FREE) && (find_free < 0))
                    find_free = index;
        end
    endfunction

    wire signed [31:0] free_index = find_free();
    wire ready_available = latest_ready_valid &&
                           (latest_ready_index < active_buffer_count) &&
                           (buffer_state[latest_ready_index] == BUFFER_READY);

    always @* begin
        status = 32'd0;
        status[0] = (cfg_request_toggle != cfg_ack_toggle);
        status[1] = (active_buffer_count != 0);
        status[2] = writer_active;
        status[3] = reader_active;
        status[6:4] = {{(3-INDEX_WIDTH){1'b0}}, writer_index};
        status[9:7] = {{(3-INDEX_WIDTH){1'b0}}, reader_index};
        status[12:10] = active_buffer_count;
        for (status_i = 0; status_i < MAX_BUFFERS; status_i = status_i + 1)
            status[16+status_i*2 +: 2] = buffer_state[status_i];
    end

    always @(posedge ui_clk) begin
        if (!ui_resetn) begin
            cfg_sync_1 <= 1'b0;
            cfg_sync_2 <= 1'b0;
            cfg_ack_toggle <= 1'b0;
            active_width <= 32'd1920;
            active_height <= 32'd1080;
            active_stride_bytes <= 32'd7680;
            active_buffer_count <= 3'd0;
            writer_active <= 1'b0;
            reader_active <= 1'b0;
            writer_index <= {INDEX_WIDTH{1'b0}};
            reader_index <= {INDEX_WIDTH{1'b0}};
            drop_reported <= 1'b0;
            latest_ready_valid <= 1'b0;
            latest_ready_index <= {INDEX_WIDTH{1'b0}};
            reader_grant <= 1'b0;
            writer_base <= 32'd0;
            reader_base <= 32'd0;
            writer_frame_count <= 32'd0;
            reader_frame_count <= 32'd0;
            drop_count <= 32'd0;
            underflow_count <= 32'd0;
            for (i = 0; i < MAX_BUFFERS; i = i + 1) begin
                active_bases[i] <= 32'd0;
                buffer_state[i] <= BUFFER_FREE;
            end
        end else begin
            cfg_sync_1 <= cfg_request_toggle;
            cfg_sync_2 <= cfg_sync_1;
            writer_grant <= 1'b0;
            writer_drop <= 1'b0;
            reader_grant <= 1'b0;

            // Apply a complete shadow configuration only between frames.
            if ((cfg_sync_2 != cfg_ack_toggle) && !writer_active &&
                !writer_grant && !writer_drop && !reader_active) begin
                active_width <= cfg_width;
                active_height <= cfg_height;
                active_stride_bytes <= cfg_stride_bytes;
                if (cfg_enable && (cfg_buffer_count >= 2) &&
                    (cfg_buffer_count <= MAX_BUFFERS) &&
                    (cfg_width != 0) && (cfg_height != 0) &&
                    (cfg_width[2:0] == 0) &&
                    (cfg_stride_bytes >= cfg_width * 4) &&
                    (cfg_stride_bytes[4:0] == 0))
                    active_buffer_count <= cfg_buffer_count[2:0];
                else
                    active_buffer_count <= 3'd0;
                for (i = 0; i < MAX_BUFFERS; i = i + 1) begin
                    active_bases[i] <= cfg_buffer_bases[i*32 +: 32];
                    buffer_state[i] <= BUFFER_FREE;
                end
                writer_grant <= 1'b0;
                writer_drop <= 1'b0;
                latest_ready_valid <= 1'b0;
                latest_ready_index <= {INDEX_WIDTH{1'b0}};
                cfg_ack_toggle <= cfg_sync_2;
            end else begin
                if ((writer_done || writer_error) && writer_active) begin
                    writer_active <= 1'b0;
                    if (writer_error)
                        buffer_state[writer_index] <= BUFFER_FREE;
                    else begin
                        buffer_state[writer_index] <= BUFFER_READY;
                        latest_ready_valid <= 1'b1;
                        latest_ready_index <= writer_index;
                        writer_frame_count <= writer_frame_count + 1'b1;
                    end
                end

                if (reader_done && reader_active) begin
                    reader_frame_count <= reader_frame_count + 1'b1;
                    // Switching is only legal after the reader has emitted
                    // the complete current frame.  With no READY successor,
                    // retain ownership so the same frame can be replayed.
                    if (ready_available) begin
                        buffer_state[reader_index] <= BUFFER_FREE;
                        reader_index <= latest_ready_index;
                        reader_base <= active_bases[latest_ready_index];
                        buffer_state[latest_ready_index] <= BUFFER_READING;
                        // Display the newest complete frame.  Older READY
                        // frames can never be useful to a low-latency video
                        // path, so return them to the writer pool.
                        for (i = 0; i < MAX_BUFFERS; i = i + 1)
                            if ((buffer_state[i] == BUFFER_READY) &&
                                (i != latest_ready_index))
                                buffer_state[i] <= BUFFER_FREE;
                        // A writer completion in this same cycle is newer
                        // than the buffer being consumed.  Preserve the
                        // writer block's latest-ready update in that case.
                        if (!(writer_done && writer_active && !writer_error))
                            latest_ready_valid <= 1'b0;
                    end
                end

                if (reader_underflow)
                    underflow_count <= underflow_count + 1'b1;

                if (!writer_acquire)
                    drop_reported <= 1'b0;

                // Commit a registered response only when the writer still
                // presents acquire.  This keeps manager ownership exactly in
                // step with the writer's accepted grant/drop handshake.
                if (writer_grant) begin
                    writer_grant <= 1'b0;
                    if (writer_acquire) begin
                        writer_active <= 1'b1;
                        buffer_state[writer_index] <= BUFFER_WRITING;
                        drop_reported <= 1'b1;
                    end
                end else if (writer_drop) begin
                    writer_drop <= 1'b0;
                    if (writer_acquire) begin
                        drop_count <= drop_count + 1'b1;
                        drop_reported <= 1'b1;
                    end
                end else if (writer_acquire &&
                             (active_buffer_count != 0) &&
                             !((writer_done || writer_error) &&
                               writer_active)) begin
                    if (writer_active) begin
                        // Completion is observed one cycle after the writer
                        // releases its context.  Never convert that temporary
                        // skew into a whole-frame drop.
                    end else if (free_index >= 0) begin
                        writer_index <= free_index[INDEX_WIDTH-1:0];
                        writer_base <= active_bases[free_index];
                        writer_grant <= 1'b1;
                    end else if (!drop_reported) begin
                        writer_drop <= 1'b1;
                    end
                end

                // reader_done and the next acquire can overlap.  Defer the
                // grant for one cycle so a boundary switch cannot return the
                // just-released old address.
                if (reader_acquire && !reader_done) begin
                    if (reader_active) begin
                        reader_base <= active_bases[reader_index];
                        reader_grant <= 1'b1;
                    end else if (!reader_active && (active_buffer_count != 0)) begin
                        if (ready_available) begin
                            reader_active <= 1'b1;
                            reader_index <= latest_ready_index;
                            reader_base <= active_bases[latest_ready_index];
                            buffer_state[latest_ready_index] <= BUFFER_READING;
                            for (i = 0; i < MAX_BUFFERS; i = i + 1)
                                if ((buffer_state[i] == BUFFER_READY) &&
                                    (i != latest_ready_index))
                                    buffer_state[i] <= BUFFER_FREE;
                            if (!(writer_done && writer_active && !writer_error))
                                latest_ready_valid <= 1'b0;
                            reader_grant <= 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
