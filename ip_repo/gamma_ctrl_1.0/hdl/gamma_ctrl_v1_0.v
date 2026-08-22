
`timescale 1 ns / 1 ps

	module gamma_ctrl_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Master Bus Interface M00_AXI 
		parameter  C_M00_AXI_START_DATA_VALUE	= 32'hAA000000,
		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 32,
		parameter integer C_M00_AXI_TRANSACTIONS_NUM	= 1541
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Master Bus Interface M00_AXI
		//input wire  m00_axi_init_axi_txn,
		output wire  m00_axi_error,
		output wire  m00_axi_txn_done,
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [2 : 0] m00_axi_awprot,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [1 : 0] m00_axi_bresp,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [2 : 0] m00_axi_arprot,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready
	);
reg [10:0] addr_wcnt;
reg [10:0] data_wcnt;
reg [C_M00_AXI_ADDR_WIDTH-1 : 0] awaddr;
reg [C_M00_AXI_ADDR_WIDTH-1 : 0] araddr;
reg [C_M00_AXI_DATA_WIDTH-1 : 0] axi_wdata;
reg init_axi_txn;

wire [C_M00_AXI_DATA_WIDTH-1 : 0] rom_data;
	
assign m00_axi_init_axi_txn = init_axi_txn;	
assign m00_axi_awaddr = awaddr;
assign m00_axi_araddr = araddr;
assign m00_axi_wdata  = axi_wdata;	
	
// Instantiation of Axi Bus Interface M00_AXI
	gamma_ctrl_v1_0_M00_AXI # ( 
		.C_M_START_DATA_VALUE(C_M00_AXI_START_DATA_VALUE),
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_TRANSACTIONS_NUM(C_M00_AXI_TRANSACTIONS_NUM)
	) gamma_ctrl_v1_0_M00_AXI_inst (
		.INIT_AXI_TXN(m00_axi_init_axi_txn),
		.ERROR(m00_axi_error),
		.TXN_DONE(m00_axi_txn_done),
		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWADDR(),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARADDR(),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);
reg [8:0] rom_addr;
blk_mem_gen_0 u_blk_mem_gen_0 (
  .clka(m00_axi_aclk),    // input wire clka
  .addra(rom_addr),  // input wire [8 : 0] addra
  .douta(rom_data)  // output wire [31 : 0] douta
);

always@(posedge m00_axi_aclk or negedge m00_axi_aresetn )begin
    if(!m00_axi_aresetn)
        rom_addr <= 9'd0;
    else if(addr_wcnt > 11'd3 && addr_wcnt < 11'd1540 &&m00_axi_wvalid && m00_axi_wready)
        rom_addr <= rom_addr + 1'b1;
    else
        rom_addr <= rom_addr ;
end

	// Add user logic here
always@(posedge m00_axi_aclk or negedge m00_axi_aresetn )begin
    if(!m00_axi_aresetn)
        addr_wcnt <= 11'd0;
    else if(m00_axi_awvalid && m00_axi_awready) 
        addr_wcnt <= addr_wcnt + 1'b1;
    else
        ;
end

always@(posedge m00_axi_aclk or negedge m00_axi_aresetn )begin
    if(!m00_axi_aresetn)
        data_wcnt <= 11'd0;
    else if(m00_axi_wvalid && m00_axi_wready) 
        data_wcnt <= data_wcnt + 1'b1;
    else
        ;
end

always@(*)begin
    case (data_wcnt)
        11'd0:begin
             
                axi_wdata <= 32'd1920; 
             end
        11'd1:begin
              
                axi_wdata <= 32'd1080;
             end
        11'd2:begin
              
                axi_wdata <= 32'd0;
             end
        11'd1539:begin
              
                axi_wdata <= 32'd128;
             end
        11'd1540:begin
               
                axi_wdata <= 32'd129;
             end
        default:begin
                  
                    axi_wdata <= rom_data;
                end
    endcase
end

always@(*)begin
    case (addr_wcnt)
        32'd0:begin
                awaddr <= 32'd16;
               
             end
        32'd1:begin
                awaddr <= 32'd24;
             
             end
        32'd2:begin
                awaddr <= 32'd32;
               
             end
        32'd1539:begin
                awaddr <= 32'h00;
          
             end
        32'd1540:begin
                awaddr <= 32'h00;
              
             end
        default:begin
                    awaddr <= 2036 + {addr_wcnt,2'b00};
                 
                end
    endcase
end

always@(posedge m00_axi_aclk or negedge m00_axi_aresetn )begin
    if(!m00_axi_aresetn)
        init_axi_txn <= 1'b0;
    else
        init_axi_txn <= 1'b1;
end
	// User logic ends

	endmodule
