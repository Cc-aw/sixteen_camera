module axi_lite_monitor (
    input             clk,
    input             rst_n,

    input      [5:0]  demo_awaddr,
    input             demo_awvalid,
    input             demo_awready,
    input      [31:0] demo_wdata,
    input             demo_wvalid,
    input             demo_wready,
    input             demo_bvalid,
    input             demo_bready,

    input      [12:0] gamma_awaddr,
    input             gamma_awvalid,
    input             gamma_awready,
    input      [31:0] gamma_wdata,
    input             gamma_wvalid,
    input             gamma_wready,
    input             gamma_bvalid,
    input             gamma_bready,

    input      [31:0] csirxss_m_axi_awaddr,
    input      [31:0] csirxss_m_axi_araddr,
    output      [7:0] csirxss_s_axi_awaddr,
    output      [7:0] csirxss_s_axi_araddr,

    output            demo_config_done,
    output            gamma_config_done
);

    wire demo_ctrl_aw_hs;
    wire demo_ctrl_w_hs;
    wire demo_ctrl_b_hs;
    wire gamma_ctrl_aw_hs;
    wire gamma_ctrl_w_hs;
    wire gamma_ctrl_b_hs;

    reg [5:0]  demo_ctrl_awaddr_hold;
    reg [31:0] demo_ctrl_wdata_hold;
    reg        demo_ctrl_aw_seen;
    reg        demo_ctrl_w_seen;
    reg        demo_ctrl_b_seen;
    reg [3:0]  demo_ctrl_b_count;
    reg [5:0]  demo_ctrl_last_commit_addr;
    reg [31:0] demo_ctrl_last_commit_data;
    reg        demo_ctrl_start_write_seen;
    reg        demo_ctrl_config_done_seen;

    reg [12:0] gamma_ctrl_awaddr_hold;
    reg [31:0] gamma_ctrl_wdata_hold;
    reg        gamma_ctrl_aw_seen;
    reg        gamma_ctrl_w_seen;
    reg        gamma_ctrl_b_seen;
    reg [11:0] gamma_ctrl_b_count;
    reg [12:0] gamma_ctrl_last_commit_addr;
    reg [31:0] gamma_ctrl_last_commit_data;
    reg        gamma_ctrl_start_write_seen;
    reg        gamma_ctrl_config_done_seen;

    assign csirxss_s_axi_awaddr = csirxss_m_axi_awaddr[7:0];
    assign csirxss_s_axi_araddr = csirxss_m_axi_araddr[7:0];
    assign demo_ctrl_aw_hs = demo_awvalid && demo_awready;
    assign demo_ctrl_w_hs = demo_wvalid && demo_wready;
    assign demo_ctrl_b_hs = demo_bvalid && demo_bready;
    assign gamma_ctrl_aw_hs = gamma_awvalid && gamma_awready;
    assign gamma_ctrl_w_hs = gamma_wvalid && gamma_wready;
    assign gamma_ctrl_b_hs = gamma_bvalid && gamma_bready;
    assign demo_config_done = demo_ctrl_config_done_seen;
    assign gamma_config_done = gamma_ctrl_config_done_seen;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            demo_ctrl_awaddr_hold       <= 6'd0;
            demo_ctrl_wdata_hold        <= 32'd0;
            demo_ctrl_aw_seen           <= 1'b0;
            demo_ctrl_w_seen            <= 1'b0;
            demo_ctrl_b_seen            <= 1'b0;
            demo_ctrl_b_count           <= 4'd0;
            demo_ctrl_last_commit_addr  <= 6'd0;
            demo_ctrl_last_commit_data  <= 32'd0;
            demo_ctrl_start_write_seen  <= 1'b0;
            demo_ctrl_config_done_seen  <= 1'b0;
        end else begin
            if(demo_ctrl_aw_hs) begin
                demo_ctrl_aw_seen <= 1'b1;
                demo_ctrl_awaddr_hold <= demo_awaddr;
            end

            if(demo_ctrl_w_hs) begin
                demo_ctrl_w_seen <= 1'b1;
                demo_ctrl_wdata_hold <= demo_wdata;
            end

            if(demo_ctrl_b_hs) begin
                demo_ctrl_b_seen <= 1'b1;
                if(demo_ctrl_b_count != 4'hf)
                    demo_ctrl_b_count <= demo_ctrl_b_count + 1'b1;
                demo_ctrl_last_commit_addr <= demo_ctrl_awaddr_hold;
                demo_ctrl_last_commit_data <= demo_ctrl_wdata_hold;
                if(demo_ctrl_awaddr_hold == 6'h00 && demo_ctrl_wdata_hold == 32'h00000081)
                    demo_ctrl_start_write_seen <= 1'b1;
                if(demo_ctrl_b_count >= 4'd4)
                    demo_ctrl_config_done_seen <= 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            gamma_ctrl_awaddr_hold       <= 13'd0;
            gamma_ctrl_wdata_hold        <= 32'd0;
            gamma_ctrl_aw_seen           <= 1'b0;
            gamma_ctrl_w_seen            <= 1'b0;
            gamma_ctrl_b_seen            <= 1'b0;
            gamma_ctrl_b_count           <= 12'd0;
            gamma_ctrl_last_commit_addr  <= 13'd0;
            gamma_ctrl_last_commit_data  <= 32'd0;
            gamma_ctrl_start_write_seen  <= 1'b0;
            gamma_ctrl_config_done_seen  <= 1'b0;
        end else begin
            if(gamma_ctrl_aw_hs) begin
                gamma_ctrl_aw_seen <= 1'b1;
                gamma_ctrl_awaddr_hold <= gamma_awaddr;
            end

            if(gamma_ctrl_w_hs) begin
                gamma_ctrl_w_seen <= 1'b1;
                gamma_ctrl_wdata_hold <= gamma_wdata;
            end

            if(gamma_ctrl_b_hs) begin
                gamma_ctrl_b_seen <= 1'b1;
                if(gamma_ctrl_b_count != 12'hfff)
                    gamma_ctrl_b_count <= gamma_ctrl_b_count + 1'b1;
                gamma_ctrl_last_commit_addr <= gamma_ctrl_awaddr_hold;
                gamma_ctrl_last_commit_data <= gamma_ctrl_wdata_hold;
                if(gamma_ctrl_awaddr_hold == 13'h000 && gamma_ctrl_wdata_hold == 32'h00000081)
                    gamma_ctrl_start_write_seen <= 1'b1;
                if(gamma_ctrl_b_count >= 12'd1540)
                    gamma_ctrl_config_done_seen <= 1'b1;
            end
        end
    end

endmodule
