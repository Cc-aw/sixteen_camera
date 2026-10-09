`timescale 1ns/1ps

// One command at a time; six independently addressed, location-major raw
// class/DFL heads.  All intermediate sigmoid, softmax, boxes, sorting and
// NMS stay in this clock domain.  The reader interface is shared with the
// existing FBus diagnostic at descriptor boundaries.
module yolov5nu_postprocessor #(parameter ENABLE_PERF_COUNTERS = 1, parameter CLASS_FOLD_BYTES = 32, parameter ENABLE_HEAD_READY = 0) (
    input wire clk, input wire resetn,
    input wire start,
    input wire [5:0] head_ready,
    input wire abort_command,
    input wire [32:0] class0, class1, class2,
    input wire [32:0] dfl0, dfl1, dfl2,
    output reg read_start,
    output reg [32:0] read_base,
    output reg [31:0] read_bytes,
    input wire read_busy, read_done, read_error,
    input wire [255:0] stream_data,
    input wire [31:0] stream_keep,
    input wire stream_valid, stream_last,
    output wire stream_ready,
    input wire [4:0] result_index,
    output wire [127:0] result_word,
    output wire [5:0] result_count,
    output reg busy, output reg done, output reg error,
    output wire [12:0] positions_seen,
    output wire [12:0] candidates_seen,
    output wire [15:0] nms_candidates_seen,
    output wire [575:0] perf_values,
    output reg [31:0] cycles
);
    localparam [3:0] IDLE=0, CLASS_LAUNCH=1, CLASS_STREAM=2,
        CLASS_DRAIN=3, DFL_LAUNCH=4, DFL_STREAM=5,
        DFL_DRAIN=6, NMS_WAIT=7, COMPLETE=8,
        CLEAR_HIST=9, CUTOFF_SCAN=10, DFL_SCAN=11, ABORT_DRAIN=12, ABORT_RESET=13;
    wire datapath_resetn = resetn && state != ABORT_RESET;
    reg [3:0] state;
    reg [1:0] head;
    reg [12:0] location;
    reg [12:0] scan_location;
    reg [6:0] scan_x;
    reg [5:0] scan_y;
    reg [1:0] scan_head;
    reg [7:0] histogram_index;
    reg [7:0] score_scan;
    reg [12:0] better_count;
    reg [8:0] cutoff_quota;
    reg signed [7:0] cutoff_score;
    reg [12:0] score_histogram [0:255];
    reg half;
    reg wait_decoder;
    reg [255:0] first_half;
    reg [511:0] raw_dfl;
    reg dfl_start, class_start, nms_start, nms_finish;
    reg finish_sent;
    reg [14:0] class_meta [0:6299];
    reg [127:0] result_ram [0:9];
    reg [5:0] stored_count;
    wire [255:0] mapped_class;
    wire [255:0] class_stream = mapped_class;
    wire class_stream_ready, class_result_valid, class_done, class_error;
    wire [12:0] class_position, class_candidates_seen;
    wire [12:0] class_positions_seen;
    wire [6:0] class_result_class;
    wire signed [7:0] class_result_score;
    wire class_result_candidate, class_result_last;
    wire class_busy, class_compute_active;
    wire sort_active, nms_active;
    wire [2:0] class_flags;
    wire [31:0] dfl_distances;
    wire dfl_valid, dfl_busy;
    wire [127:0] candidate_word, nms_result;
    wire nms_candidate_ready, nms_result_valid, nms_done, nms_busy;
    wire nms_result_last, nms_error;
    wire bbox_ready, bbox_valid;
    wire [7:0] bbox_score;
    wire [8:0] nms_retained;
    wire [5:0] nms_count;

    assign positions_seen = class_positions_seen;
    assign candidates_seen = class_candidates_seen;
    assign result_count = stored_count;
    assign result_word = result_index < 10 && result_index < stored_count ?
                         result_ram[result_index] : 128'd0;

    for (genvar lane=0; lane<32; lane=lane+1) begin : g_class_rom
        yolov5nu_raw_class_lut u_rom (
            .head(head), .raw(stream_data[lane*8 +: 8]),
            .score(mapped_class[lane*8 +: 8])
        );
    end

    yolov5nu_class_reducer #(.FOLD_BYTES(CLASS_FOLD_BYTES)) u_class (
        .clk(clk), .resetn(datapath_resetn), .start(class_start),
        .score_threshold(8'sd34),
        .s_data(class_stream), .s_keep(stream_keep),
        .s_valid(stream_valid && state == CLASS_STREAM),
        .s_ready(class_stream_ready),
        .s_last(stream_last && head == 2),
        .result_valid(class_result_valid), .result_ready(1'b1),
        .result_position(class_position),
        .result_class(class_result_class),
        .result_score(class_result_score),
        .result_candidate(class_result_candidate),
        .result_last(class_result_last),
        .compute_active(class_compute_active), .busy(class_busy), .done(class_done), .error(class_error),
        .error_flags(class_flags), .positions_seen(class_positions_seen),
        .candidates_seen(class_candidates_seen)
    );

    yolov5nu_dfl_decoder u_dfl (
        .clk(clk), .resetn(datapath_resetn), .start(dfl_start),
        .head(head), .logits(raw_dfl),
        .busy(dfl_busy), .valid(dfl_valid),
        .ready(bbox_ready &&
               (state == DFL_STREAM || state == DFL_DRAIN)),
        .distances(dfl_distances)
    );
    yolov5nu_bbox_pipeline u_bbox (
        .clk(clk),.resetn(datapath_resetn),
        .in_valid(dfl_valid && (state == DFL_STREAM || state == DFL_DRAIN)),
        .in_ready(bbox_ready), .out_valid(bbox_valid), .out_ready(nms_candidate_ready),
        .position(location-13'd1), .head(scan_head), .grid_x(scan_x), .grid_y(scan_y),
        .class_id(class_meta[location-13'd1][14:8]),
        .score_i8(class_meta[location-13'd1][7:0]), .distances(dfl_distances),
        .candidate(candidate_word), .raw_score(bbox_score)
    );
    yolov5nu_bucket_nms #(.RESULT_LIMIT(10)) u_nms (
        .clk(clk), .resetn(datapath_resetn), .start(nms_start),
        .candidate_data(candidate_word),
        .candidate_score(bbox_score), .error(nms_error),
        .candidate_valid(bbox_valid),
        .candidate_ready(nms_candidate_ready),
        .candidates_finished(nms_finish),
        .result_data(nms_result), .result_valid(nms_result_valid),
        .result_ready(1'b1), .result_last(nms_result_last),
        .sort_active(sort_active), .nms_active(nms_active),
        .busy(nms_busy), .done(nms_done),
        .candidates_seen(nms_candidates_seen),
        .retained_count(nms_retained), .result_count(nms_count)
    );

    wire [16:0] perf_events;
    assign perf_events[0] = busy;
    assign perf_events[1] = state == CLASS_STREAM && stream_valid && stream_ready;
    assign perf_events[2] = class_compute_active;
    assign perf_events[3] = state == CLASS_STREAM && stream_valid && !stream_ready;
    assign perf_events[4] = state == CUTOFF_SCAN;
    assign perf_events[5] = state == DFL_SCAN;
    assign perf_events[6] = state == DFL_STREAM && stream_valid && stream_ready;
    assign perf_events[7] = dfl_busy;
    assign perf_events[8] = sort_active;
    assign perf_events[9] = nms_active;
    assign perf_events[10] = nms_result_valid;
    assign perf_events[11] = dfl_start;
    assign perf_events[12] = state == CLEAR_HIST;
    assign perf_events[13] = dfl_valid && !bbox_ready;
    assign perf_events[14] = class_result_valid && class_result_candidate;
    assign perf_events[15] = read_busy && stream_ready && !stream_valid;
    assign perf_events[16] = state == CLASS_LAUNCH || state == DFL_LAUNCH;
    ppu_perf_counters #(.ENABLE(ENABLE_PERF_COUNTERS)) u_perf (
        .clk(clk), .resetn(datapath_resetn), .clear(start && state == IDLE),
        .events(perf_events), .values(perf_values)
    );

    task advance_scan;
        begin
            scan_location <= scan_location + 1'b1;
            if (scan_location == 4799 || scan_location == 5999) begin
                scan_x <= 0; scan_y <= 0; scan_head <= scan_head+1'b1;
            end else if (scan_x == (scan_head==0 ? 79 : scan_head==1 ? 39 : 19)) begin
                scan_x <= 0; scan_y <= scan_y+1'b1;
            end else scan_x <= scan_x+1'b1;
        end
    endtask

    assign stream_ready = state == ABORT_DRAIN ? 1'b1 : state == CLASS_STREAM ? class_stream_ready :
        (state == DFL_STREAM && !wait_decoder);

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            head <= 0;
            location <= 0;
            half <= 0;
            busy <= 0;
            done <= 0;
            error <= 0;
            read_start <= 0;
            read_base <= 0;
            read_bytes <= 0;
            dfl_start <= 0;
            class_start <= 0;
            nms_start <= 0;
            nms_finish <= 0;
            finish_sent <= 0;
            wait_decoder <= 0;
            stored_count <= 0;
            cycles <= 0;
        end else begin
            read_start <= 0;
            dfl_start <= 0;
            class_start <= 0;
            nms_start <= 0;
            nms_finish <= 0;
            if (busy) cycles <= cycles + 1'b1;
            if (class_result_valid && class_position < 13'd6300) begin
                class_meta[class_position] <=
                    {class_result_class, class_result_score[7:0]};
                if (class_result_candidate)
                    score_histogram[class_result_score[7:0]] <=
                        score_histogram[class_result_score[7:0]] + 1'b1;
            end
            if (nms_result_valid && stored_count < 10) begin
                result_ram[stored_count[3:0]] <= nms_result;
                stored_count <= stored_count + 1'b1;
            end
            if (bbox_valid && nms_candidate_ready)
                wait_decoder <= 0;
            if (nms_error && state == NMS_WAIT) error <= 1;
            case (state)
            IDLE: if (start) begin
                state <= CLEAR_HIST;
                busy <= 1;
                done <= 0;
                error <= 0;
                head <= 0;
                location <= 0;
                half <= 0;
                stored_count <= 0;
                cycles <= 0;
                finish_sent <= 0;
                nms_start <= 1;
                histogram_index <= 0;
            end
            CLEAR_HIST: begin
                score_histogram[histogram_index] <= 0;
                histogram_index <= histogram_index + 1'b1;
                if (histogram_index == 8'd255) begin
                    class_start <= 1;
                    state <= CLASS_LAUNCH;
                end
            end
            CLASS_LAUNCH: if (!read_busy && (!ENABLE_HEAD_READY || head_ready[head])) begin
                case (head)
                0: read_base <= class0;
                1: read_base <= class1;
                default: read_base <= class2;
                endcase
                case (head)
                0: read_bytes <= 32'd384000;
                1: read_bytes <= 32'd96000;
                default: read_bytes <= 32'd24000;
                endcase
                read_start <= 1;
                state <= CLASS_STREAM;
            end
            CLASS_STREAM: if (read_done) begin
                if (read_error) begin
                    error <= 1;
                    state <= COMPLETE;
                end else if (head == 2) state <= CLASS_DRAIN;
                else begin
                    head <= head + 1'b1;
                    state <= CLASS_LAUNCH;
                end
            end
            CLASS_DRAIN: if (class_done || !class_busy) begin
                if (class_error || positions_seen != 13'd6300) begin
                    error <= 1;
                    state <= COMPLETE;
                end else begin
                    score_scan <= 8'd127;
                    better_count <= 0;
                    state <= CUTOFF_SCAN;
                end
            end
            // Only the best 256 class scores can survive the existing NMS
            // heap.  At an equal score, lower location wins.  Determine the
            // cutoff before issuing any DFL reads, then scan in location
            // order so ties remain identical to the full-head path.
            CUTOFF_SCAN: begin
                if (better_count + score_histogram[score_scan] >= 13'd256 ||
                    score_scan == 8'd34) begin
                    cutoff_score <= $signed(score_scan);
                    cutoff_quota <= 9'd256 - better_count[8:0];
                    scan_location <= 0;
                    scan_x <= 0; scan_y <= 0; scan_head <= 0;
                    state <= DFL_SCAN;
                end else begin
                    better_count <= better_count + score_histogram[score_scan];
                    score_scan <= score_scan - 1'b1;
                end
            end
            DFL_SCAN: begin
                if (scan_location == 13'd6300)
                    state <= NMS_WAIT;
                else if ($signed(class_meta[scan_location][7:0]) >
                             cutoff_score ||
                         ($signed(class_meta[scan_location][7:0]) ==
                             cutoff_score && cutoff_quota != 0)) begin
                    if ($signed(class_meta[scan_location][7:0]) == cutoff_score)
                        cutoff_quota <= cutoff_quota - 1'b1;
                    state <= DFL_LAUNCH;
                end else
                    advance_scan();
            end
            DFL_LAUNCH: if (!read_busy && (!ENABLE_HEAD_READY || head_ready[3+scan_head])) begin
                if (scan_location < 13'd4800) begin
                    head <= 0;
                    read_base <= dfl0 + {14'd0, scan_location, 6'b0};
                end else if (scan_location < 13'd6000) begin
                    head <= 1;
                    read_base <= dfl1 +
                        {14'd0, (scan_location - 13'd4800), 6'b0};
                end else begin
                    head <= 2;
                    read_base <= dfl2 +
                        {14'd0, (scan_location - 13'd6000), 6'b0};
                end
                read_bytes <= 32'd64;
                read_start <= 1;
                state <= DFL_STREAM;
                half <= 0;
            end
            DFL_STREAM: begin
                if (stream_valid && stream_ready) begin
                    half <= !half;
                    if (!half) first_half <= stream_data;
                    else begin
                        raw_dfl <= {stream_data, first_half};
                        dfl_start <= 1;
                        wait_decoder <= 1;
                        location <= scan_location + 1'b1;
                    end
                    if (stream_keep != 32'hffff_ffff) error <= 1;
                end
                if (read_done) begin
                    if (read_error || half) error <= 1;
                    state <= DFL_DRAIN;
                end
            end
            DFL_DRAIN: if (!wait_decoder && !dfl_busy && !dfl_valid) begin
                if (error) state <= COMPLETE;
                else begin
                    advance_scan();
                    state <= DFL_SCAN;
                end
            end
            NMS_WAIT: begin
                if (!finish_sent && nms_candidate_ready) begin
                    nms_finish <= 1;
                    finish_sent <= 1;
                end
                if (nms_done) state <= COMPLETE;
            end
            ABORT_DRAIN: if (!read_busy && !read_start) state <= ABORT_RESET;
            ABORT_RESET: begin stored_count <= 0; state <= COMPLETE; end
            COMPLETE: begin
                done <= 1;
                busy <= 0;
                state <= IDLE;
            end
            default: state <= IDLE;
            endcase
            if (ENABLE_HEAD_READY && abort_command && busy && state != ABORT_DRAIN && state != ABORT_RESET && state != COMPLETE) begin
                error <= 1; state <= ABORT_DRAIN;
                read_start <= 0; class_start <= 0; dfl_start <= 0; nms_start <= 0;
            end
        end
    end
endmodule
