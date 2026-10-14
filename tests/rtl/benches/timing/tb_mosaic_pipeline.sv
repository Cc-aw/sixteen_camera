`timescale 1ns/1ps
module tb_mosaic_pipeline;
    reg clk=0;
    always #3 clk=~clk;
    reg resetn=0, grant=0;
    wire acquire, done, axi_error, underflow;
    reg [511:0] bases;
    localparam [15:0] VALID=16'hadf7;
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if axis();
    mosaic_rgb565_reader dut(.clk(clk), .resetn(resetn),
        .buffer_acquire(acquire), .buffer_grant(grant), .buffer_bases(bases),
        .buffer_valid_mask(VALID), .buffer_done(done), .m_axi(axi),
        .m_axis(axis), .axi_error(axi_error), .fifo_underflow(underflow), .debug_status());
    integer pending=0, cycles=0, beats=0, bursts=0, boundaries=0;
    integer x=0,y=0;
    reg [31:0] response_addr=0, ar_saved;
    reg [7:0] len_saved;
    reg ar_stalled=0, axis_stalled=0;
    reg [47:0] data_saved;
    reg user_saved,last_saved;
    function automatic [15:0] pixel(input integer c, row, col);
        pixel=16'((c*2783) ^ (row*67) ^ (col*137));
    endfunction
    function automatic [23:0] expand(input [15:0] p);
        expand={p[15:11],p[15:13],p[10:5],p[10:9],p[4:0],p[4:2]};
    endfunction
    function automatic [255:0] ddr_data(input [31:0] addr);
        integer c,row,first,k,relative;
        c=(addr-32'h81000000)>>20;
        relative=integer'(addr-(32'h81000fe0+c*32'h00100000));
        row=relative/736;
        first=(relative%736)/2;
        for(k=0;k<16;k=k+1) ddr_data[k*16+:16]=pixel(c,row,first+k);
    endfunction
    function automatic [47:0] expected(input integer row, pair_x);
        integer tile, local_x,c,py;
        tile=pair_x/240; local_x=pair_x%240;
        c=(row/270)*4+tile; py=row%270;
        if(local_x<30 || local_x>=210 || !VALID[c]) expected=0;
        else expected={expand(pixel(c,py,(local_x-30)*2+1)),
                       expand(pixel(c,py,(local_x-30)*2))};
    endfunction
    initial begin
        for(integer i=0;i<16;i=i+1) bases[i*32+:32]=32'h81000fe0+i*32'h00100000;
        axi.awready=0; axi.wready=0; axi.bid=0; axi.bresp=0; axi.bvalid=0;
        axi.arready=0; axi.rid=0; axi.rresp=0; axi.rvalid=0; axi.rlast=0; axi.rdata=0;
        axis.tready=0;
        repeat(8) @(negedge clk);
        resetn=1; grant=1;
        @(negedge clk); grant=0;
        forever begin
            @(negedge clk);
            axi.arready=($urandom_range(0,4)!=0);
            axis.tready=($urandom_range(0,5)!=0);
            axi.rvalid=pending>0 && ($urandom_range(0,3)!=0);
            axi.rdata=ddr_data(response_addr);
            axi.rlast=pending==1;
        end
    end
    always @(posedge clk) if(resetn) begin
        cycles=cycles+1;
        if(cycles>3000000) $fatal(1,"mosaic timeout x=%0d y=%0d",x,y);
        if(ar_stalled && (!axi.arvalid || axi.araddr!=ar_saved || axi.arlen!=len_saved))
            $fatal(1,"AR changed under backpressure");
        ar_stalled=axi.arvalid && !axi.arready;
        ar_saved=axi.araddr; len_saved=axi.arlen;
        if(axis_stalled && (!axis.tvalid || axis.tdata!=data_saved ||
                           axis.tuser!=user_saved || axis.tlast!=last_saved))
            $fatal(1,"AXIS changed under backpressure");
        axis_stalled=axis.tvalid && !axis.tready;
        data_saved=axis.tdata; user_saved=axis.tuser; last_saved=axis.tlast;
        if(axi.arvalid && axi.arready) begin
            if(pending!=0) $fatal(1,"unexpected second outstanding read");
            if(axi.araddr[4:0]!=0 || axi.arsize!=5 || axi.arburst!=1 ||
               integer'(axi.araddr[11:0])+32*(integer'(axi.arlen)+1)>4096)
                $fatal(1,"illegal burst addr=%h len=%0d",axi.araddr,axi.arlen);
            if(integer'(axi.araddr[11:0])+32*(integer'(axi.arlen)+1)==4096) boundaries++;
            pending=integer'(axi.arlen)+1; response_addr=axi.araddr; bursts++;
        end
        if(axi.rvalid && axi.rready) begin
            if(pending==0) $fatal(1,"response without request");
            pending--; response_addr=response_addr+32;
        end
        if(axis.tvalid && axis.tready) begin
            if(axis.tdata!==expected(y,x) || axis.tuser!==(x==0 && y==0) || axis.tlast!==(x==959))
                $fatal(1,"pixel mismatch x=%0d y=%0d actual=%h expected=%h",x,y,axis.tdata,expected(y,x));
            beats++;
            if(x==959) begin x=0;y++;end else x++;
        end
        if(axi_error) $fatal(1,"unexpected AXI error");
        if(done) begin
            if(beats!=1036800 || y!=1080 || pending!=0 || boundaries==0)
                $fatal(1,"bad frame completion beats=%0d y=%0d pending=%0d",beats,y,pending);
            $display("MOSAIC_PIPELINE=PASS beats=%0d bursts=%0d boundary_splits=%0d cycles=%0d",beats,bursts,boundaries,cycles);
            $finish;
        end
    end
endmodule
