`timescale 1ns/1ps

module tb_yolov5nu_postprocessor;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0, start=0;
    wire read_start;
    wire [32:0] read_base;
    wire [31:0] read_bytes;
    reg read_busy=0, read_done=0, read_error=0;
    wire [255:0] stream_data;
    wire [31:0] stream_keep=32'hffffffff;
    wire stream_valid=read_busy;
    wire stream_last;
    wire stream_ready;
    reg [4:0] result_index=0;
    wire [127:0] result_word;
    wire [5:0] result_count;
    wire busy, done, error;
    wire [12:0] positions_seen, candidates_seen;
    wire [15:0] nms_candidates_seen;
    wire [31:0] cycles;
    reg [7:0] raw_classes [0:503999];
    reg [31:0] current_bytes, current_offset, consumed;
    reg current_class;
    reg dense, empty_case;
    reg [31:0] dfl_bytes;

    yolov5nu_postprocessor dut (
        .clk(clk), .resetn(resetn), .start(start),
        .class0(33'h1000), .class1(33'h2000), .class2(33'h3000),
        .dfl0(33'h4000), .dfl1(33'h5000), .dfl2(33'h6000),
        .read_start(read_start), .read_base(read_base),
        .read_bytes(read_bytes), .read_busy(read_busy),
        .read_done(read_done), .read_error(read_error),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_last(stream_last),
        .stream_ready(stream_ready), .result_index(result_index),
        .result_word(result_word), .result_count(result_count),
        .busy(busy), .done(done), .error(error),
        .positions_seen(positions_seen), .candidates_seen(candidates_seen),
        .nms_candidates_seen(nms_candidates_seen), .cycles(cycles)
    );

    for (genvar byte_lane=0; byte_lane<32; byte_lane++) begin : g_data
        assign stream_data[byte_lane*8 +: 8] = current_class ?
            raw_classes[current_offset+consumed+byte_lane] : 8'd0;
    end
    assign stream_last = consumed + 32 == current_bytes;

    always @(posedge clk) begin
        if (!resetn) begin
            read_busy <= 0;
            read_done <= 0;
            consumed <= 0;
            current_bytes <= 0;
            current_offset <= 0;
            current_class <= 0;
            dfl_bytes <= 0;
        end else begin
            read_done <= 0;
            if (read_start && !read_busy) begin
                current_class <= read_base < 33'h4000;
                if (read_base >= 33'h4000) begin
                    if (dense && read_base != 33'h4000 + dfl_bytes)
                        $fatal(1, "dense equal-score TopK changed location order: addr=%h expected=%h",
                               read_base, 33'h4000 + dfl_bytes);
                    dfl_bytes <= dfl_bytes + read_bytes;
                end
                current_offset <= read_base == 33'h1000 ? 0 :
                                  read_base == 33'h2000 ? 384000 :
                                  read_base == 33'h3000 ? 480000 : 0;
                current_bytes <= read_bytes;
                consumed <= 0;
                read_busy <= 1;
            end else if (read_busy && stream_ready) begin
                consumed <= consumed + 32;
                if (stream_last) begin
                    read_busy <= 0;
                    read_done <= 1;
                end
            end
        end
    end

    initial begin
        $readmemh("raw_classes.mem", raw_classes);
        dense = $test$plusargs("dense");
        empty_case = $test$plusargs("empty");
        if (dense)
            for (int position=0; position<300; position++)
                raw_classes[position*80] = 8'h7f;
        if (empty_case)
            for (int index=0; index<504000; index++)
                raw_classes[index] = 8'h80;
        repeat (5) @(negedge clk);
        resetn=1;
        start=1;
        @(negedge clk);
        start=0;
        wait(done);
        if (error || positions_seen != 6300 ||
            (!dense && !empty_case && candidates_seen != 10) ||
            (dense && candidates_seen <= 256) ||
            (empty_case && candidates_seen != 0) ||
            nms_candidates_seen != (dense ? 256 : empty_case ? 0 : 10) ||
            dfl_bytes != (dense ? 256*64 : empty_case ? 0 : 10*64) ||
            (!empty_case && result_count == 0) ||
            (empty_case && result_count != 0) ||
            result_count > 10)
            $fatal(1, "raw-head pipeline error: %b pos=%0d cand=%0d nms=%0d dflB=%0d count=%0d state=%0d",
                   error, positions_seen, candidates_seen,
                   nms_candidates_seen, dfl_bytes, result_count, dut.state);
        if (!dense && !empty_case &&
            (result_word[99:87] != 6155 || result_word[86:80] != 23))
            $fatal(1, "first result is not image025 dog: %h", result_word);
        $display("yolov5nu raw-head integrated pipeline PASS: dense=%0d results=%0d dflB=%0d cycles=%0d",
                 dense, result_count, dfl_bytes, cycles);
        $finish;
    end

    initial begin
        repeat (500000) @(posedge clk);
        $fatal(1, "raw-head pipeline timeout state=%0d pos=%0d loc=%0d wait=%b",
               dut.state, positions_seen, dut.location, dut.wait_decoder);
    end
endmodule
