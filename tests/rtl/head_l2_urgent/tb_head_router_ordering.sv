`timescale 1ns/1ps
module tb_head_router_ordering #(
    parameter integer DATA_WIDTH = 512,
    parameter integer ID_WIDTH = 2,
    parameter bit READ_DECOUPLE = 1'b1,
    parameter bit SHADOW_DDR = 1'b0
);
    localparam integer IDS = 2**ID_WIDTH;
    localparam integer BYTES = DATA_WIDTH/8;
    localparam integer SHIFT = $clog2(BYTES);
    localparam integer WORDS = 4096/BYTES;
    reg clk=0, resetn=0;
    always #5 clk=~clk;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(DATA_WIDTH),.ID_WIDTH(ID_WIDTH)) s(), d();
    reg [2:0] ppu_bank=0;
    reg ppu_req=0, ppu_ready=0;
    reg [6:0] ppu_addr=0;
    wire ppu_req_ready, ppu_valid;
    wire [255:0] ppu_data;
    axi4_head_uram_router_v3 #(.DATA_WIDTH(DATA_WIDTH),.ID_WIDTH(ID_WIDTH),
        .SLOT_BYTES(4096),.READ_DECOUPLE(READ_DECOUPLE),.SHADOW_DDR(SHADOW_DDR)) dut (
        .clk(clk),.resetn(resetn),.s_axi(s),.m_ddr_axi(d),
        .local_read_bank(ppu_bank),.local_read_req_valid(ppu_req),
        .local_read_req_ready(ppu_req_ready),.local_read_req_word_addr(ppu_addr),
        .local_read_rsp_data(ppu_data),.local_read_rsp_valid(ppu_valid),.local_read_rsp_ready(ppu_ready)
    );
    typedef struct packed {
        logic [ID_WIDTH-1:0] id;
        logic [32:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
        logic lock;
        logic [3:0] cache;
        logic [2:0] prot;
        logic [3:0] qos;
    } desc_t;
    desc_t expected [IDS][64];
    desc_t accepted_ddr [IDS][64], pending_ddr [IDS][64];
    integer ew [IDS], er [IDS], eb [IDS], aw [IDS], ar [IDS], dw [IDS], dr [IDS];
    integer accepted=0, completed=0, beats=0, ddr_addresses=0;
    integer local_early=0, ddr_during_local=0, other_id_progress=0;
    integer peak=0, seed=1, request_count=10000;
    reg [31:0] rng=1;
    reg [IDS-1:0] allow_return='1;
    reg random_ready=0, random_arready=0, auto_ddr=1;
    integer responding=-1, response_beat=0, pick, bank, ix;
    desc_t response_desc, out_desc;
    reg [32:0] out_addr, ddr_addr;
    reg [DATA_WIDTH-1:0] wanted;
    reg [1:0] wanted_resp;
    reg output_burst=0;
    reg [ID_WIDTH-1:0] output_id;
    reg old_stall=0;
    reg [DATA_WIDTH+ID_WIDTH+2:0] old_payload;
    reg [DATA_WIDTH-1:0] model [6][WORDS];

    function automatic [32:0] base(input integer n);
        case(n)
            0:base=33'h32000000;1:base=33'h32100000;2:base=33'h32400000;
            3:base=33'h32500000;4:base=33'h32800000;default:base=33'h32900000;
        endcase
    endfunction
    function automatic integer head_bank(input [32:0] address);
        reg [32:0] a;
        a=address & ~33'h080000000;
        head_bank=-1;
        for(integer b=0;b<6;b++) if(a>=base(b) && a<base(b)+4096) head_bank=b;
    endfunction
    function automatic bit legal(input desc_t x);
        reg [33:0] a, finish;
        a={1'b0,(x.addr & ~33'h080000000)};
        finish=a+((34'd1<<x.size)*(x.burst==1?({1'b0,x.len}+9'd1):9'd1));
        return head_bank(x.addr)>=0 && x.size<=SHIFT && x.burst<2 &&
            finish<={1'b0,base(head_bank(x.addr))}+4096;
    endfunction
    function automatic [DATA_WIDTH-1:0] pattern(input [32:0] a);
        for(integer b=0;b<BYTES;b++) pattern[b*8+:8]=8'((a>>SHIFT)*17+b*3+(a>>28));
    endfunction
    function automatic [32:0] beat_addr(input desc_t x,input integer beat);
        return x.addr+(x.burst==1?33'(beat)*(33'd1<<x.size):33'd0);
    endfunction
    always @(posedge clk) begin
        if(!resetn) begin
            for(integer id=0;id<IDS;id++) begin
                ew[id]=0;er[id]=0;eb[id]=0;aw[id]=0;ar[id]=0;dw[id]=0;dr[id]=0;
            end
            accepted=0;completed=0;beats=0;ddr_addresses=0;
            responding=-1;response_beat=0;output_burst=0;old_stall=0;
        end else begin
            if(s.arvalid && s.arready) begin
                expected[s.arid][ew[s.arid]%64]='{s.arid,s.araddr,s.arlen,s.arsize,s.arburst,
                    s.arlock,s.arcache,s.arprot,s.arqos};
                ew[s.arid]++;
                if(head_bank(s.araddr)<0 || SHADOW_DDR) begin
                    accepted_ddr[s.arid][aw[s.arid]%64]='{s.arid,s.araddr,s.arlen,s.arsize,s.arburst,
                        s.arlock,s.arcache,s.arprot,s.arqos};aw[s.arid]++;
                end
                accepted++;
                if(accepted-completed>peak) peak=accepted-completed;
            end
            if(d.arvalid && d.arready) begin
                if(ar[d.arid]>=aw[d.arid] || accepted_ddr[d.arid][ar[d.arid]%64] !==
                    desc_t'({d.arid,d.araddr,d.arlen,d.arsize,d.arburst,d.arlock,d.arcache,d.arprot,d.arqos}))
                    $fatal(1,"DDR AR metadata/order id=%0d",d.arid);
                ar[d.arid]++;
                pending_ddr[d.arid][dw[d.arid]%64]='{d.arid,d.araddr,d.arlen,d.arsize,d.arburst,
                    d.arlock,d.arcache,d.arprot,d.arqos};dw[d.arid]++;ddr_addresses++;
                if(READ_DECOUPLE && !SHADOW_DDR && dut.head_active) ddr_during_local++;
                if(d.arid==1 && ew[0]>er[0]) other_id_progress++;
            end
            if(old_stall && (!s.rvalid || {s.rid,s.rdata,s.rresp,s.rlast} !== old_payload))
                $fatal(1,"stalled R changed");
            old_stall=s.rvalid && !s.rready;
            old_payload={s.rid,s.rdata,s.rresp,s.rlast};
            if(s.rvalid && s.rready) begin
                if(er[s.rid]>=ew[s.rid]) $fatal(1,"unaccepted response");
                out_desc=expected[s.rid][er[s.rid]%64];out_addr=beat_addr(out_desc,eb[s.rid]);
                bank=head_bank(out_desc.addr);
                if(bank<0 || SHADOW_DDR) begin wanted=pattern(out_addr);wanted_resp=2'((out_desc.addr>>6)&3); end
                else if(!legal(out_desc)) begin wanted='0;wanted_resp=3;end
                else begin ix=integer'((out_addr & 33'hfff)>>SHIFT);wanted=model[bank][ix];wanted_resp=0;end
                if(s.rdata!==wanted || s.rresp!==wanted_resp || s.rlast!==(eb[s.rid]==integer'(out_desc.len)))
                    $fatal(1,"R mismatch id=%0d addr=%h beat=%0d got=%h expected=%h resp=%d/%d last=%d",s.rid,out_desc.addr,eb[s.rid],s.rdata,wanted,s.rresp,wanted_resp,s.rlast);
                if(output_burst && s.rid!=output_id) $fatal(1,"interleaved upstream burst");
                output_id=s.rid;output_burst=!s.rlast;beats++;
                if(s.rlast) begin
                    if(bank>=0 && !SHADOW_DDR && s.rid!=0 && ew[0]>er[0]) local_early++;
                    er[s.rid]++;eb[s.rid]=0;completed++;
                end else eb[s.rid]++;
            end
            if(d.rvalid && d.rready) begin
                if(d.rlast) begin dr[responding]++;responding=-1;response_beat=0;end
                else response_beat++;
            end
        end
    end
    always @(negedge clk) begin
        if(resetn) begin
            rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
            if(random_ready) s.rready=rng[0] || rng[4];
            d.arready=!random_arready || rng[2] || rng[7];
            if(auto_ddr) begin
                if(responding<0) begin
                    for(integer off=0;off<IDS;off++) begin
                        pick=(integer'(rng[15:8])+off)%IDS;
                        if(responding<0 && allow_return[pick] && dw[pick]>dr[pick]) responding=pick;
                    end
                end
                d.rvalid=responding>=0;
                if(responding>=0) begin
                    response_desc=pending_ddr[responding][dr[responding]%64];
                    ddr_addr=beat_addr(response_desc,response_beat);
                    d.rid=ID_WIDTH'(responding);d.rdata=pattern(ddr_addr);
                    d.rresp=2'((response_desc.addr>>6)&3);d.rlast=response_beat==integer'(response_desc.len);
                end
            end
        end else d.rvalid=0;
    end
    task automatic send(input integer id,input [32:0] addr,input integer len=0,
                        input integer size=SHIFT,input integer burst=1);
        @(negedge clk);s.arid=ID_WIDTH'(id);s.araddr=addr;s.arlen=8'(len);s.arsize=3'(size);
        s.arburst=2'(burst);s.arlock=1'(addr>>8);s.arcache=4'(addr>>9);s.arprot=3'(addr>>13);s.arqos=4'(addr>>4);s.arvalid=1;
        do @(posedge clk);while(!s.arready);
        @(negedge clk);s.arvalid=0;
    endtask
    task automatic drain;
        wait(completed==accepted);repeat(5) @(negedge clk);
    endtask
    task automatic write_word(input integer b,input integer word_index,input [DATA_WIDTH-1:0] payload,input [BYTES-1:0] strobe);
        @(negedge clk);s.awaddr=base(b)+33'(word_index*BYTES);s.awvalid=1;
        do @(posedge clk);while(!s.awready);
        @(negedge clk);s.awvalid=0;s.wdata=payload;s.wstrb=strobe;s.wvalid=1;
        do @(posedge clk);while(!s.wready);
        @(negedge clk);s.wvalid=0;
        do @(posedge clk);while(!s.bvalid);
        if(s.bresp!=0) $fatal(1,"write error");
        for(integer lane=0;lane<BYTES;lane++) if(strobe[lane]) model[b][word_index][lane*8+:8]=payload[lane*8+:8];
    endtask
    task automatic check_ppu(input integer b,input integer half);
        @(negedge clk);ppu_bank=3'(b);ppu_addr=7'(half);ppu_req=1;ppu_ready=0;
        do @(posedge clk);while(!ppu_req_ready);
        @(negedge clk);ppu_req=0;
        do @(posedge clk);while(!ppu_valid);
        repeat(4) begin
            @(negedge clk);
            if(!ppu_valid || ppu_data !== model[b][half/(DATA_WIDTH/256)][(half%(DATA_WIDTH/256))*256+:256])
                $fatal(1,"PPU owner/half mismatch");
            ppu_bank=3'((b+1)%6);ppu_addr=7'(half+1);
        end
        ppu_ready=1;@(posedge clk);@(negedge clk);ppu_ready=0;
    endtask
    integer start_completed, start_addresses, old_local_early;
    initial begin
        if($value$plusargs("SEED=%d",seed)) begin end
        if($value$plusargs("REQUESTS=%d",request_count)) begin end
        rng=32'(seed);
        s.awvalid=0;s.wvalid=0;s.arvalid=0;s.bready=1;s.rready=1;
        s.awid=0;s.awlen=0;s.awsize=3'(SHIFT);s.awburst=1;s.awlock=0;s.awcache=0;s.awprot=0;s.awqos=0;
        s.arid=0;s.araddr=0;s.arlen=0;s.arsize=3'(SHIFT);s.arburst=1;s.arlock=0;s.arcache=0;s.arprot=0;s.arqos=0;
        s.wdata=0;s.wstrb='1;s.wlast=1;d.awready=1;d.wready=1;d.bvalid=0;d.bid=0;d.bresp=0;
        d.arready=1;d.rvalid=0;d.rid=0;d.rdata=0;d.rresp=0;d.rlast=0;
        repeat(5) @(negedge clk);resetn=1;
        for(integer b=0;b<6;b++) for(integer w=0;w<WORDS;w++) write_word(b,w,pattern(base(b)+33'(w*BYTES)),'1);
        for(integer b=0;b<6;b++) write_word(b,0,'1,BYTES'('h55555555));
        if($test$plusargs("PROGRESS_ONLY")) begin
            allow_return='1;allow_return[0]=0;
            send(0,33'h12000000);
            @(negedge clk);s.arid=1;s.araddr=base(1);s.arlen=0;s.arsize=3'(SHIFT);s.arvalid=1;
            start_completed=0;
            repeat(100) begin
                @(posedge clk);if(s.arvalid && s.arready) start_completed=1;
                @(negedge clk);if(start_completed) s.arvalid=0;
            end
            if((local_early>0)!==READ_DECOUPLE) $fatal(1,"baseline/candidate progress comparison");
            $display("HEAD_PROGRESS decouple=%0d head_completed_while_id0_live=%0d",READ_DECOUPLE,local_early);
            allow_return='1;
            if(!start_completed) begin
                do @(posedge clk);while(!s.arready);
                @(negedge clk);s.arvalid=0;
            end
            drain();$finish;
        end
        // H01: all 32 DDR credits can belong to one ID, beyond FIFO depth 8.
        allow_return=0;start_addresses=ddr_addresses;
        for(integer n=0;n<32;n++) send(0,33'h11000000+33'(n*BYTES));
        wait(ddr_addresses==start_addresses+32);
        if(accepted-completed!=32 || s.arready) $fatal(1,"32 same-ID DDR capacity");
        allow_return='1;drain();
        // H02/H04: ID0's local switch cannot block ID1 at either destination.
        if(READ_DECOUPLE && !SHADOW_DDR) begin
            allow_return='1;allow_return[0]=0;start_completed=completed;start_addresses=ddr_addresses;
            send(0,33'h12000000);send(0,base(0));
            old_local_early=local_early;send(1,base(1),3);
            wait(local_early>old_local_early);
            send(1,33'h13000000);
            wait(ddr_addresses==start_addresses+2);
            if(er[0]==ew[0]) $fatal(1,"Head did not overlap old DDR");
            // H03: new same-ID DDR cannot bypass its queued Head.
            send(0,33'h12000100);repeat(10) @(negedge clk);
            if(ddr_addresses!=start_addresses+2) $fatal(1,"same-ID DDR bypassed Head");
            // A waiting same-ID Head must not seize the PPU RAM.
            check_ppu(4,0);check_ppu(5,1);
            allow_return='1;drain();
            // H05/H06: Head burst stalls upstream while DDR AR keeps moving.
            s.rready=0;send(2,base(2),31);repeat(6) @(negedge clk);
            start_addresses=ddr_addresses;send(3,33'h14000000,7);
            wait(ddr_addresses>start_addresses);
            if(ddr_during_local==0) $fatal(1,"Head froze DDR AR");
            random_ready=1;random_arready=1;drain();random_ready=0;s.rready=1;
            // H08: already accepted PPU response must drain before Head owns RAM.
            @(negedge clk);ppu_bank=0;ppu_addr=1;ppu_req=1;ppu_ready=0;
            do @(posedge clk);while(!ppu_req_ready);
            @(negedge clk);ppu_req=0;send(1,base(1),2);
            repeat(8) begin @(negedge clk);if(!ppu_valid || ppu_data!==model[0][1/(DATA_WIDTH/256)][(1%(DATA_WIDTH/256))*256+:256]) $fatal(1,"PPU lost during handover");end
            ppu_ready=1;@(posedge clk);@(negedge clk);ppu_ready=0;drain();
            // H10: each ID FIFO full behind an opposite-destination owner.
            allow_return=0;
            for(integer id=0;id<IDS;id++) send(id,33'h15000000+33'(id*4096));
            for(integer n=0;n<8;n++) send(0,base(n%6));
            if(s.arready) $fatal(1,"per-ID FIFO did not fill at 8");
            for(integer n=0;n<20;n++) send(1+n%(IDS-1),base(n%6));
            if(accepted-completed!=32 || s.arready) $fatal(1,"global credit full");
            allow_return='1;random_ready=1;drain();random_ready=0;s.rready=1;
        end
        // H09: narrow/FIXED/INCR, aliases, valid edges and complete errors.
        for(integer b=0;b<6;b++) begin
            check_ppu(b,0);check_ppu(b,1);
            send(b%IDS,base(b)+4096-BYTES,0,SHIFT);send(b%IDS,base(b)+16,7,2,0);
            send(b%IDS,base(b)+33'h80000000,15,4,1);
            send(b%IDS,base(b)+4096-BYTES,1,SHIFT,1);
            send(b%IDS,base(b),3,SHIFT,2);send(b%IDS,base(b),2,SHIFT+1,1);
        end
        fork
            write_word(5,40,'1,'1);
            begin send(0,base(0),7);send(1,33'h17000000,3);end
        join
        drain();
        // ARLEN=255 is legal in a 4KiB burst with one-byte transfers.
        send(1,base(1),255,0,1);drain();
        random_ready=1;random_arready=1;
        for(integer n=0;n<request_count;n++) begin
            if(rng[4]) send(integer'(rng[11:8])%IDS,base(integer'(rng[15:12])%6)+33'(integer'(rng[23:16])%(4096/BYTES-16)*BYTES),integer'(rng[7:5]),integer'(rng[2:0])%(SHIFT+1),integer'(rng[3]));
            else send(integer'(rng[11:8])%IDS,33'h18000000+33'(rng[23:12]*4096)+33'(rng[9:6]*BYTES),integer'(rng[7:5]));
        end
        drain();random_ready=0;s.rready=1;
        // H11: common reset clears controls while preserving URAM contents.
        @(negedge clk);resetn=0;repeat(4) @(negedge clk);resetn=1;
        repeat(3) @(negedge clk);if(s.rvalid) $fatal(1,"ghost response after reset");
        check_ppu(3,1);send(2,base(3));drain();
        if(READ_DECOUPLE && !SHADOW_DDR && (local_early==0 || ddr_during_local==0 || other_id_progress==0 || peak!=32)) $fatal(1,"mechanism coverage missing");
        $display("HEAD_READ_PASS width=%0d seed=%0d random_requests=%0d local_early=%0d ddr_while_local=%0d other_id=%0d peak=%0d",DATA_WIDTH,seed,request_count,local_early,ddr_during_local,other_id_progress,peak);
        $finish;
    end
    initial begin #100000000; $fatal(1,"Head test timeout accepted=%0d completed=%0d",accepted,completed);end
endmodule
