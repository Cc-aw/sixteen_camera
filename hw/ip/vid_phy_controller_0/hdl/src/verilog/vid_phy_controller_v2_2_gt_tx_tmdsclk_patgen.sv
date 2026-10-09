// (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////
/*
    Pattern Generator for GT TX USERDATA
    This module generates the pattern for txusrdata
	to use one gt channel as reference clock source
    Written by Gilbert Magnaye
    (c) 2014, 2015 by Advanced Micro Devices inc.

    History
    -------
    v1.0 - Initial release

*/

`include "vid_phy_controller_v2_2_17_defs.v"
`default_nettype none

module vid_phy_controller_v2_2_17_gt_tx_tmdsclk_patgen #
(
	parameter integer   TXDATA_WIDTH     = 40
)
(
    input  wire         CLK_IN,                         // System Clock 
    input  wire         TXUSRCLK_IN,                    // Clock
	
    input  wire         CTRL_EN_IN,                     // Enable
    input  wire  [2:0]  CTRL_RATIO_IN,                  // Linerate to txusrdata ratio 
	
    output wire [TXDATA_WIDTH-1:0]  TXDATA_OUT          // txdata to GT Channel
	
);

// Logic
wire            ctrl_en_in_sync;
wire     [2:0]  ctrl_ratio_in_sync;
logic    [3:0]  txdata_counter;
logic    [3:0]  txdata_count;
logic   [39:0]  txdata_out_1;
logic   [39:0]  txdata_out_2;
logic   [39:0]  txdata_out_3;
logic   [39:0]  txdata_out_4;
logic   [39:0]  txdata_out_5;
logic   [TXDATA_WIDTH-1:0]  txdata_out_int;

localparam      LR_RATIO_10_VAL  = 3'b001;
localparam      LR_RATIO_20_VAL  = 3'b010;
localparam      LR_RATIO_30_VAL  = 3'b011;
localparam      LR_RATIO_40_VAL  = 3'b100;
localparam      LR_RATIO_50_VAL  = 3'b101;

localparam      LR_RATIO_10_CNT  = (TXDATA_WIDTH == 40) ? 1 : 2;
localparam      LR_RATIO_20_CNT  = (TXDATA_WIDTH == 40) ? 1 : 2;
localparam      LR_RATIO_30_CNT  = (TXDATA_WIDTH == 40) ? 3 : 6;
localparam      LR_RATIO_40_CNT  = (TXDATA_WIDTH == 40) ? 1 : 2;
localparam      LR_RATIO_50_CNT  = (TXDATA_WIDTH == 40) ? 5 : 10;

localparam      LR_RATIO_10_DATA   = { 5'b11111, 5'b00000, 5'b11111, 5'b00000, 5'b11111, 5'b00000, 5'b11111, 5'b00000 };
localparam      LR_RATIO_20_DATA   = { 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b11111, 5'b11111, 5'b00000, 5'b00000 };
localparam      LR_RATIO_30_DATA1  = { 5'b00000, 5'b00000, 5'b11111, 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b00000 };
localparam      LR_RATIO_30_DATA2  = { 5'b11111, 5'b00000, 5'b00000, 5'b00000, 5'b11111, 5'b11111, 5'b11111, 5'b00000 };
localparam      LR_RATIO_30_DATA3  = { 5'b11111, 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b00000, 5'b11111, 5'b11111 };
localparam      LR_RATIO_40_DATA   = { 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b00000, 5'b00000 };
localparam      LR_RATIO_50_DATA1  = { 5'b11111, 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b00000, 5'b00000, 5'b00000 };
localparam      LR_RATIO_50_DATA2  = { 5'b11111, 5'b00000, 5'b00000, 5'b00000, 5'b00000, 5'b00000, 5'b11111, 5'b11111 };
localparam      LR_RATIO_50_DATA3  = { 5'b00000, 5'b00000, 5'b00000, 5'b00000, 5'b11111, 5'b11111, 5'b11111, 5'b11111 };
localparam      LR_RATIO_50_DATA4  = { 5'b00000, 5'b00000, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b00000 };
localparam      LR_RATIO_50_DATA5  = { 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b11111, 5'b00000, 5'b00000, 5'b00000 };


// CTRL_EN_IN Sync
xpm_cdc_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	RESET_IN_SYNC_INST 
	(
		.src_clk         (CLK_IN        ),
		.src_in          (CTRL_EN_IN),
		.dest_clk        (TXUSRCLK_IN),
		.dest_out        (ctrl_en_in_sync)
	);

// CTRL_RATIO_IN Sync
xpm_cdc_array_single 
	#(
		.VERSION        (`XPM_CDC_VERSION       ),
		.SIM_ASSERT_CHK (`XPM_CDC_SIM_ASSERT_CHK),
		.DEST_SYNC_FF   (`XPM_CDC_MTBF_FFS      ),
		.WIDTH          ( 3                     ),
		.SRC_INPUT_REG  ( 0                     )
	) 
	BIT_REP_IN_SYNC_INST 
	(
		.src_clk         (CLK_IN),
		.src_in          (CTRL_RATIO_IN),
		.dest_clk        (TXUSRCLK_IN),
		.dest_out        (ctrl_ratio_in_sync)
    );

// Prepare TXOUT_DATA per CTRL_RATIO_IN
always @ (posedge TXUSRCLK_IN)
begin
	if (~ctrl_en_in_sync)
	begin
		txdata_count <= 4'b1;
		txdata_out_1 <= 40'b0;
		txdata_out_2 <= 40'b0;
		txdata_out_3 <= 40'b0;
		txdata_out_4 <= 40'b0;
		txdata_out_5 <= 40'b0;
	end
	
	else
	begin
        case (ctrl_ratio_in_sync)
            LR_RATIO_10_VAL : 
            begin
                txdata_count <= LR_RATIO_10_CNT;
                txdata_out_1 <= LR_RATIO_10_DATA;
                txdata_out_2 <= LR_RATIO_10_DATA;
                txdata_out_3 <= LR_RATIO_10_DATA;
                txdata_out_4 <= LR_RATIO_10_DATA;
                txdata_out_5 <= LR_RATIO_10_DATA;
            end

            LR_RATIO_20_VAL : 
            begin
                txdata_count <= LR_RATIO_20_CNT;
                txdata_out_1 <= LR_RATIO_20_DATA;
                txdata_out_2 <= LR_RATIO_20_DATA;
                txdata_out_3 <= LR_RATIO_20_DATA;
                txdata_out_4 <= LR_RATIO_20_DATA;
                txdata_out_5 <= LR_RATIO_20_DATA;
            end

            LR_RATIO_30_VAL : 
            begin
                txdata_count <= LR_RATIO_30_CNT;
                txdata_out_1 <= LR_RATIO_30_DATA1;
                txdata_out_2 <= LR_RATIO_30_DATA2;
                txdata_out_3 <= LR_RATIO_30_DATA3;
                txdata_out_4 <= 40'b0;
                txdata_out_5 <= 40'b0;
            end

            LR_RATIO_40_VAL : 
            begin
                txdata_count <= LR_RATIO_40_CNT;
                txdata_out_1 <= LR_RATIO_40_DATA;
                txdata_out_2 <= LR_RATIO_40_DATA;
                txdata_out_3 <= LR_RATIO_40_DATA;
                txdata_out_4 <= LR_RATIO_40_DATA;
                txdata_out_5 <= LR_RATIO_40_DATA;
            end

            LR_RATIO_50_VAL : 
            begin
                txdata_count <= LR_RATIO_50_CNT;
                txdata_out_1 <= LR_RATIO_50_DATA1;
                txdata_out_2 <= LR_RATIO_50_DATA2;
                txdata_out_3 <= LR_RATIO_50_DATA3;
                txdata_out_4 <= LR_RATIO_50_DATA4;
                txdata_out_5 <= LR_RATIO_50_DATA5;
            end
            
            default : 
            begin
                txdata_count <= 4'b1;
                txdata_out_1 <= 40'b0;
                txdata_out_2 <= 40'b0;
                txdata_out_3 <= 40'b0;
                txdata_out_4 <= 40'b0;
                txdata_out_5 <= 40'b0;
            end
        endcase
	end
end



generate
    if (TXDATA_WIDTH == 40)
        begin 
            // Construct TXOUT_DATA 
            always_ff @ (posedge TXUSRCLK_IN)
            begin
                if (~ctrl_en_in_sync)
                    txdata_counter = 4'b0;
                else if (txdata_counter == txdata_count)
                    txdata_counter = 4'b1;
                else	
                    txdata_counter = txdata_counter + 1;
            end

            always_ff @ (posedge TXUSRCLK_IN)
            begin
                if (~ctrl_en_in_sync)
                begin
                    txdata_out_int <= 40'b0;
                end
                
                else	
                begin
                    case (txdata_counter)
                        4'h1 : txdata_out_int <= txdata_out_1;
                        4'h2 : txdata_out_int <= txdata_out_2;
                        4'h3 : txdata_out_int <= txdata_out_3;
                        4'h4 : txdata_out_int <= txdata_out_4;
                        4'h5 : txdata_out_int <= txdata_out_5;
                        default : txdata_out_int <= 40'b0;
                    endcase
                end
            end
        end
    else  //(TXDATA_WIDTH == 20)
        begin 
            // Construct TXOUT_DATA 
            always_ff @ (posedge TXUSRCLK_IN)
            begin
                if (~ctrl_en_in_sync)
                    txdata_counter = 4'b0;
                else if (txdata_counter == txdata_count)
                    txdata_counter = 4'b1;
                else	
                    txdata_counter = txdata_counter + 1;
            end

            always_ff @ (posedge TXUSRCLK_IN)
            begin
                if (~ctrl_en_in_sync)
                begin
                    txdata_out_int <= 20'b0;
                end
                
                else	
                begin
                    case (txdata_counter)
                        4'h1 : txdata_out_int <= txdata_out_1[19:0];
                        4'h2 : txdata_out_int <= txdata_out_1[39:20];
                        4'h3 : txdata_out_int <= txdata_out_2[19:0];
                        4'h4 : txdata_out_int <= txdata_out_2[39:20];
                        4'h5 : txdata_out_int <= txdata_out_3[19:0];
                        4'h6 : txdata_out_int <= txdata_out_3[39:20];
                        4'h7 : txdata_out_int <= txdata_out_4[19:0];
                        4'h8 : txdata_out_int <= txdata_out_4[39:20];
                        4'h9 : txdata_out_int <= txdata_out_5[19:0];
                        4'hA : txdata_out_int <= txdata_out_5[39:20];
                        default : txdata_out_int <= 20'b0;
                    endcase
                end
            end
        end
endgenerate

// Module Output
assign TXDATA_OUT           = txdata_out_int;

endmodule

`default_nettype wire
