`timescale 1ns/1ps

// One command at a time; six independently addressed, location-major raw
// class/DFL heads.  All intermediate sigmoid, softmax, boxes, sorting and
// NMS stay in this clock domain.  The reader interface is shared with the
// existing FBus diagnostic at descriptor boundaries.
module yolov5nu_postprocessor (
    input wire clk, input wire resetn,
    input wire start,
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
    output reg [31:0] cycles
);
    localparam [3:0] IDLE=0, CLASS_LAUNCH=1, CLASS_STREAM=2,
        CLASS_DRAIN=3, DFL_LAUNCH=4, DFL_STREAM=5,
        DFL_DRAIN=6, NMS_WAIT=7, COMPLETE=8;
    reg [3:0] state;
    reg [1:0] head;
    reg [12:0] location;
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
    wire class_busy;
    wire [2:0] class_flags;
    wire [31:0] dfl_distances;
    wire dfl_valid, dfl_busy;
    wire [127:0] candidate_word, nms_result;
    wire nms_candidate_ready, nms_result_valid, nms_done, nms_busy;
    wire nms_result_last;
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

    yolov5nu_class_reducer u_class (
        .clk(clk), .resetn(resetn), .start(class_start),
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
        .busy(class_busy), .done(class_done), .error(class_error),
        .error_flags(class_flags), .positions_seen(class_positions_seen),
        .candidates_seen(class_candidates_seen)
    );

    yolov5nu_dfl_decoder u_dfl (
        .clk(clk), .resetn(resetn), .start(dfl_start),
        .head(head), .logits(raw_dfl),
        .busy(dfl_busy), .valid(dfl_valid),
        .ready(nms_candidate_ready &&
               (state == DFL_STREAM || state == DFL_DRAIN)),
        .distances(dfl_distances)
    );
    yolov5nu_bbox_decoder u_bbox (
        .position(location-13'd1),
        .class_id(class_meta[location-13'd1][14:8]),
        .score_i8(class_meta[location-13'd1][7:0]),
        .distance_left(dfl_distances[7:0]),
        .distance_top(dfl_distances[15:8]),
        .distance_right(dfl_distances[23:16]),
        .distance_bottom(dfl_distances[31:24]),
        .candidate(candidate_word)
    );
    yolov5nu_topk_nms #(.RESULT_LIMIT(10)) u_nms (
        .clk(clk), .resetn(resetn), .start(nms_start),
        .candidate_data(candidate_word),
        .candidate_valid(dfl_valid &&
                         (state == DFL_STREAM || state == DFL_DRAIN)),
        .candidate_ready(nms_candidate_ready),
        .candidates_finished(nms_finish),
        .result_data(nms_result), .result_valid(nms_result_valid),
        .result_ready(1'b1), .result_last(nms_result_last),
        .busy(nms_busy), .done(nms_done),
        .candidates_seen(nms_candidates_seen),
        .retained_count(nms_retained), .result_count(nms_count)
    );

    assign stream_ready = state == CLASS_STREAM ? class_stream_ready :
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
            if (class_result_valid && class_position < 13'd6300)
                class_meta[class_position] <=
                    {class_result_class, class_result_score[7:0]};
            if (nms_result_valid && stored_count < 10) begin
                result_ram[stored_count[3:0]] <= nms_result;
                stored_count <= stored_count + 1'b1;
            end
            if (dfl_valid && nms_candidate_ready &&
                (state == DFL_STREAM || state == DFL_DRAIN))
                wait_decoder <= 0;
            case (state)
            IDLE: if (start) begin
                state <= CLASS_LAUNCH;
                busy <= 1;
                done <= 0;
                error <= 0;
                head <= 0;
                location <= 0;
                half <= 0;
                stored_count <= 0;
                cycles <= 0;
                finish_sent <= 0;
                class_start <= 1;
                nms_start <= 1;
            end
            CLASS_LAUNCH: if (!read_busy) begin
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
                    head <= 0;
                    location <= 0;
                    state <= DFL_LAUNCH;
                end
            end
            DFL_LAUNCH: if (!read_busy) begin
                case (head)
                0: read_base <= dfl0;
                1: read_base <= dfl1;
                default: read_base <= dfl2;
                endcase
                case (head)
                0: read_bytes <= 32'd307200;
                1: read_bytes <= 32'd76800;
                default: read_bytes <= 32'd19200;
                endcase
                read_start <= 1;
                state <= DFL_STREAM;
                half <= 0;
            end
            DFL_STREAM: begin
                if (stream_valid && stream_ready) begin
                    half <= !half;
                    if (!half) first_half <= stream_data;
                    else begin
                        if (class_meta[location][7:0] >= 8'd34) begin
                            raw_dfl <= {stream_data, first_half};
                            dfl_start <= 1;
                            wait_decoder <= 1;
                        end
                        location <= location + 1'b1;
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
                else if (head == 2) begin
                    if (location != 13'd6300) error <= 1;
                    state <= NMS_WAIT;
                end else begin
                    head <= head + 1'b1;
                    state <= DFL_LAUNCH;
                end
            end
            NMS_WAIT: begin
                if (!finish_sent && nms_candidate_ready) begin
                    nms_finish <= 1;
                    finish_sent <= 1;
                end
                if (nms_done) state <= COMPLETE;
            end
            COMPLETE: begin
                done <= 1;
                busy <= 0;
                state <= IDLE;
            end
            default: state <= IDLE;
            endcase
        end
    end
endmodule
