//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:			i2c_ov5645_rgb565_cfg
// Last modified Date:	2023/10/10 9:19:08
// Last Version:		V1.0
// Descriptions:		iic配置
//						
//----------------------------------------------------------------------------------------
// Created by:			正点原子
// Created date:		2023/10/10 9:19:08
// Version:				V1.0
// Descriptions:		The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module i2c_ov5645_rgb565_cfg
   (  
	input				 clk	  ,		//时钟信号
	input				 rst_n	  ,		//复位信号，低电平有效

	output	reg			 cam_rst_n,	    //摄像头复位
	output	reg			 cam_pwdn, 
	
	input		 [7:0]	 i2c_data_r,	//I2C读出的数据
	input				 i2c_done ,		//I2C寄存器配置完成信号
	output	reg			 i2c_exec ,	    //I2C触发执行信号	
	output	reg	 [23:0]	 i2c_data ,	    //I2C要配置的地址与数据(高16位地址,低8位数据)
	output	reg			 i2c_rh_wl,	    //I2C读写控制信号
	output	reg			 init_done	    //初始化完成信号
	   
	);

//parameter define
localparam	REG_NUM = 9'd287  ;		  //总共需要配置的寄存器个数

//reg define
reg	  [12:0]   start_init_cnt;		//等待延时计数器
reg	   [8:0]   init_reg_cnt	 ;		//寄存器配置个数计数器
reg	  [7:0]	   i2c_done_d;			

//*****************************************************
//**					main code
//*****************************************************

//clk时钟配置成250khz,周期为4us 5000*4us = 20ms
//OV5640上电到开始配置IIC至少等待20ms
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		start_init_cnt <= 13'b0;
	else if(start_init_cnt < 13'd5000) begin
		start_init_cnt <= start_init_cnt + 1'b1;					
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		cam_pwdn <= 1'b0;
		cam_rst_n <= 1'b0;
	end
	else if(start_init_cnt == 13'd4000) begin
		cam_pwdn <= 1'b1;
		cam_rst_n <= 1'b1;					 
	end
end

//寄存器配置个数计数	   
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		init_reg_cnt <= 8'd0;
	else if(i2c_exec)	
		init_reg_cnt <= init_reg_cnt + 8'b1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		i2c_done_d <= 8'd0;
	else   
		i2c_done_d <= {i2c_done_d[6:0],i2c_done};
end

//i2c触发执行信号	  
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		i2c_exec <= 1'b0;
	else if(start_init_cnt == 13'd4999)
		i2c_exec <= 1'b1;
	else if(i2c_done_d[7] && (init_reg_cnt < REG_NUM))
		i2c_exec <= 1'b1;
	else
		i2c_exec <= 1'b0;
end 

//配置I2C读写控制信号
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		i2c_rh_wl <= 1'b1;
	else 
		i2c_rh_wl <= 1'b0;	
end

//初始化完成信号
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		init_done <= 1'b0;
	else if((init_reg_cnt == REG_NUM) && i2c_done)	
		init_done <= 1'b1;	
end

//raw10 1920x1080 30fps
//配置寄存器地址与数据
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		i2c_data <= 24'b0;
	else begin
		case(init_reg_cnt)
			9'd0    : i2c_data <={ 16'h3103, 8'h11 };
		    9'd1    : i2c_data <={ 16'h3008, 8'h82 };
		    9'd2    : i2c_data <={ 16'h3008, 8'h42 };
		    9'd3    : i2c_data <={ 16'h3103, 8'h03 };
		    9'd4    : i2c_data <={ 16'h3503, 8'h07 };
		    9'd5    : i2c_data <={ 16'h3002, 8'h1c };
		    9'd6    : i2c_data <={ 16'h3006, 8'hc3 };
		    9'd7    : i2c_data <={ 16'h3017, 8'h00 };
		    9'd8    : i2c_data <={ 16'h3018, 8'h00 };
		    9'd9    : i2c_data <={ 16'h302e, 8'h0b };
		    9'd10   : i2c_data <={ 16'h3037, 8'h13 };
		    9'd11   : i2c_data <={ 16'h3108, 8'h01 };
		    9'd12   : i2c_data <={ 16'h3611, 8'h06 };
		    9'd13   : i2c_data <={ 16'h3500, 8'h00 };
		    9'd14   : i2c_data <={ 16'h3501, 8'h01 };
		    9'd15   : i2c_data <={ 16'h3502, 8'h00 };
		    9'd16   : i2c_data <={ 16'h350a, 8'h00 };
		    9'd17   : i2c_data <={ 16'h350b, 8'h3f };
		    9'd18   : i2c_data <={ 16'h3620, 8'h33 };
		    9'd19   : i2c_data <={ 16'h3621, 8'he0 };
		    9'd20   : i2c_data <={ 16'h3622, 8'h01 };
		    9'd21   : i2c_data <={ 16'h3630, 8'h2e };
		    9'd22   : i2c_data <={ 16'h3631, 8'h00 };
		    9'd23   : i2c_data <={ 16'h3632, 8'h32 };
		    9'd24   : i2c_data <={ 16'h3633, 8'h52 };
		    9'd25   : i2c_data <={ 16'h3634, 8'h70 };
		    9'd26   : i2c_data <={ 16'h3635, 8'h13 };
		    9'd27   : i2c_data <={ 16'h3636, 8'h03 };
		    9'd28   : i2c_data <={ 16'h3703, 8'h5a };
		    9'd29   : i2c_data <={ 16'h3704, 8'ha0 };
		    9'd30   : i2c_data <={ 16'h3705, 8'h1a };
		    9'd31   : i2c_data <={ 16'h3709, 8'h12 };
		    9'd32   : i2c_data <={ 16'h370b, 8'h61 };
		    9'd33   : i2c_data <={ 16'h370f, 8'h10 };
		    9'd34   : i2c_data <={ 16'h3715, 8'h78 };
		    9'd35   : i2c_data <={ 16'h3717, 8'h01 };
		    9'd36   : i2c_data <={ 16'h371b, 8'h20 };
		    9'd37   : i2c_data <={ 16'h3731, 8'h12 };
		    9'd38   : i2c_data <={ 16'h3901, 8'h0a };
		    9'd39   : i2c_data <={ 16'h3905, 8'h02 };
		    9'd40   : i2c_data <={ 16'h3906, 8'h10 };
		    9'd41   : i2c_data <={ 16'h3719, 8'h86 };
		    9'd42   : i2c_data <={ 16'h3820, 8'h02 };//图像翻转寄存器
		    9'd43   : i2c_data <={ 16'h3821, 8'h04 };//图像镜像寄存器
		    9'd44   : i2c_data <={ 16'h3824, 8'h01 };
		    9'd45   : i2c_data <={ 16'h3826, 8'h03 };
		    9'd46   : i2c_data <={ 16'h3828, 8'h08 };
		    9'd47   : i2c_data <={ 16'h3a19, 8'hf8 };
		    9'd48   : i2c_data <={ 16'h3c01, 8'h34 };
		    9'd49   : i2c_data <={ 16'h3c04, 8'h28 };
		    9'd50   : i2c_data <={ 16'h3c05, 8'h98 };
		    9'd51   : i2c_data <={ 16'h3c07, 8'h07 };
		    9'd52   : i2c_data <={ 16'h3c09, 8'hc2 };
		    9'd53   : i2c_data <={ 16'h3c0a, 8'h9c };
		    9'd54   : i2c_data <={ 16'h3c0b, 8'h40 };
		    9'd55   : i2c_data <={ 16'h3c01, 8'h34 };
		    9'd56   : i2c_data <={ 16'h4001, 8'h02 };
		    9'd57   : i2c_data <={ 16'h4514, 8'h00 };
		    9'd58   : i2c_data <={ 16'h4520, 8'hb0 };
		    9'd59   : i2c_data <={ 16'h460b, 8'h37 };
		    9'd60   : i2c_data <={ 16'h460c, 8'h20 };
		    9'd61   : i2c_data <={ 16'h4818, 8'h01 };
		    9'd62   : i2c_data <={ 16'h481d, 8'hf0 };
		    9'd63   : i2c_data <={ 16'h481f, 8'h50 };
		    9'd64   : i2c_data <={ 16'h4823, 8'h70 };
		    9'd65   : i2c_data <={ 16'h4831, 8'h14 };
		    9'd66   : i2c_data <={ 16'h5000, 8'h81 };//bit[7]：镜头校正；bit[5]：GAMMA使能；bit[2]：黑像素消除；bit[1]：白像素消除；bit[0]：颜色插值.
		    9'd67   : i2c_data <={ 16'h5001, 8'h05 };
		    9'd68   : i2c_data <={ 16'h5003, 8'h0a };
		    9'd69   : i2c_data <={ 16'h501d, 8'h00 };
		    9'd70   : i2c_data <={ 16'h501f, 8'h03 };
		    9'd71   : i2c_data <={ 16'h503d, 8'h00 };//测试模式选择：00有效数据，80：彩条
		    9'd72   : i2c_data <={ 16'h505c, 8'h30 };
		    9'd73   : i2c_data <={ 16'h5181, 8'h59 };
		    9'd74   : i2c_data <={ 16'h5183, 8'h00 };
		    9'd75   : i2c_data <={ 16'h5191, 8'hf0 };
		    9'd76   : i2c_data <={ 16'h5192, 8'h03 };
		    9'd77   : i2c_data <={ 16'h5684, 8'h10 };
		    9'd78   : i2c_data <={ 16'h5685, 8'ha0 };
		    9'd79   : i2c_data <={ 16'h5686, 8'h0c };
		    9'd80   : i2c_data <={ 16'h5687, 8'h78 };
		    9'd81   : i2c_data <={ 16'h5a00, 8'h08 };
		    9'd82   : i2c_data <={ 16'h5a21, 8'h00 };
		    9'd83   : i2c_data <={ 16'h5a24, 8'h00 };
		    9'd84   : i2c_data <={ 16'h3008, 8'h02 };
		    9'd85   : i2c_data <={ 16'h3503, 8'h00 };
		    9'd86   : i2c_data <={ 16'h5180, 8'hff };
		    9'd87   : i2c_data <={ 16'h5181, 8'hf2 };
		    9'd88   : i2c_data <={ 16'h5182, 8'h00 };
		    9'd89   : i2c_data <={ 16'h5183, 8'h14 };
		    9'd90   : i2c_data <={ 16'h5184, 8'h25 };
		    9'd91   : i2c_data <={ 16'h5185, 8'h24 };
		    9'd92   : i2c_data <={ 16'h5186, 8'h09 };
		    9'd93   : i2c_data <={ 16'h5187, 8'h09 };
		    9'd94   : i2c_data <={ 16'h5188, 8'h0a };
		    9'd95   : i2c_data <={ 16'h5189, 8'h75 };
		    9'd96   : i2c_data <={ 16'h518a, 8'h52 };
		    9'd97   : i2c_data <={ 16'h518b, 8'hea };
		    9'd98   : i2c_data <={ 16'h518c, 8'ha8 };
		    9'd99   : i2c_data <={ 16'h518d, 8'h42 };
		    9'd100  : i2c_data <={ 16'h518e, 8'h38 };
		    9'd101  : i2c_data <={ 16'h518f, 8'h56 };
		    9'd102  : i2c_data <={ 16'h5190, 8'h42 };
		    9'd103  : i2c_data <={ 16'h5191, 8'hf8 };
		    9'd104  : i2c_data <={ 16'h5192, 8'h04 };
		    9'd105  : i2c_data <={ 16'h5193, 8'hfd };
		    9'd106  : i2c_data <={ 16'h5194, 8'ha7 };
		    9'd107  : i2c_data <={ 16'h5195, 8'hfc };
		    9'd108  : i2c_data <={ 16'h5196, 8'h03 };
		    9'd109  : i2c_data <={ 16'h5197, 8'h01 };
		    9'd110  : i2c_data <={ 16'h5198, 8'h04 };
		    9'd111  : i2c_data <={ 16'h5199, 8'h12 };
		    9'd112  : i2c_data <={ 16'h519a, 8'h04 };
		    9'd113  : i2c_data <={ 16'h519b, 8'h00 };
		    9'd114  : i2c_data <={ 16'h519c, 8'h06 };
		    9'd115  : i2c_data <={ 16'h519d, 8'h82 };
		    9'd116  : i2c_data <={ 16'h519e, 8'h38 };
		    9'd117  : i2c_data <={ 16'h5381, 8'h1e };
		    9'd118  : i2c_data <={ 16'h5382, 8'h5b };
		    9'd119  : i2c_data <={ 16'h5383, 8'h08 };
		    9'd120  : i2c_data <={ 16'h5384, 8'h0a };
		    9'd121  : i2c_data <={ 16'h5385, 8'h7e };
		    9'd122  : i2c_data <={ 16'h5386, 8'h88 };
		    9'd123  : i2c_data <={ 16'h5387, 8'h7c };
		    9'd124  : i2c_data <={ 16'h5388, 8'h6c };
		    9'd125  : i2c_data <={ 16'h5389, 8'h10 };
		    9'd126  : i2c_data <={ 16'h538a, 8'h01 };
		    9'd127  : i2c_data <={ 16'h538b, 8'h98 };
		    9'd128  : i2c_data <={ 16'h5300, 8'h08 };
		    9'd129  : i2c_data <={ 16'h5301, 8'h30 };
		    9'd130  : i2c_data <={ 16'h5302, 8'h10 };
		    9'd131  : i2c_data <={ 16'h5303, 8'h00 };
		    9'd132  : i2c_data <={ 16'h5304, 8'h08 };
		    9'd133  : i2c_data <={ 16'h5305, 8'h30 };
		    9'd134  : i2c_data <={ 16'h5306, 8'h08 };
		    9'd135  : i2c_data <={ 16'h5307, 8'h16 };
		    9'd136  : i2c_data <={ 16'h5309, 8'h08 };
		    9'd137  : i2c_data <={ 16'h530a, 8'h30 };
		    9'd138  : i2c_data <={ 16'h530b, 8'h04 };
		    9'd139  : i2c_data <={ 16'h530c, 8'h06 };
		    9'd140  : i2c_data <={ 16'h5480, 8'h01 };
		    9'd141  : i2c_data <={ 16'h5481, 8'h08 };
		    9'd142  : i2c_data <={ 16'h5482, 8'h14 };
		    9'd143  : i2c_data <={ 16'h5483, 8'h28 };
		    9'd144  : i2c_data <={ 16'h5484, 8'h51 };
		    9'd145  : i2c_data <={ 16'h5485, 8'h65 };
		    9'd146  : i2c_data <={ 16'h5486, 8'h71 };
		    9'd147  : i2c_data <={ 16'h5487, 8'h7d };
		    9'd148  : i2c_data <={ 16'h5488, 8'h87 };
		    9'd149  : i2c_data <={ 16'h5489, 8'h91 };
		    9'd150  : i2c_data <={ 16'h548a, 8'h9a };
		    9'd151  : i2c_data <={ 16'h548b, 8'haa };
		    9'd152  : i2c_data <={ 16'h548c, 8'hb8 };
		    9'd153  : i2c_data <={ 16'h548d, 8'hcd };
		    9'd154  : i2c_data <={ 16'h548e, 8'hdd };
		    9'd155  : i2c_data <={ 16'h548f, 8'hea };
		    9'd156  : i2c_data <={ 16'h5490, 8'h1d };
		    9'd157  : i2c_data <={ 16'h5580, 8'h02 };
		    9'd158  : i2c_data <={ 16'h5583, 8'h40 };
		    9'd159  : i2c_data <={ 16'h5584, 8'h10 };
		    9'd160  : i2c_data <={ 16'h5589, 8'h10 };
		    9'd161  : i2c_data <={ 16'h558a, 8'h00 };
		    9'd162  : i2c_data <={ 16'h558b, 8'hf8 };
		    9'd163  : i2c_data <={ 16'h5800, 8'h3f };
		    9'd164  : i2c_data <={ 16'h5801, 8'h16 };
		    9'd165  : i2c_data <={ 16'h5802, 8'h0e };
		    9'd166  : i2c_data <={ 16'h5803, 8'h0d };
		    9'd167  : i2c_data <={ 16'h5804, 8'h17 };
		    9'd168  : i2c_data <={ 16'h5805, 8'h3f };
		    9'd169  : i2c_data <={ 16'h5806, 8'h0b };
		    9'd170  : i2c_data <={ 16'h5807, 8'h06 };
		    9'd171  : i2c_data <={ 16'h5808, 8'h04 };
		    9'd172  : i2c_data <={ 16'h5809, 8'h04 };
		    9'd173  : i2c_data <={ 16'h580a, 8'h06 };
		    9'd174  : i2c_data <={ 16'h580b, 8'h0b };
		    9'd175  : i2c_data <={ 16'h580c, 8'h09 };
		    9'd176  : i2c_data <={ 16'h580d, 8'h03 };
		    9'd177  : i2c_data <={ 16'h580e, 8'h00 };
		    9'd178  : i2c_data <={ 16'h580f, 8'h00 };
		    9'd179  : i2c_data <={ 16'h5810, 8'h03 };
		    9'd180  : i2c_data <={ 16'h5811, 8'h08 };
		    9'd181  : i2c_data <={ 16'h5812, 8'h0a };
		    9'd182  : i2c_data <={ 16'h5813, 8'h03 };
		    9'd183  : i2c_data <={ 16'h5814, 8'h00 };
		    9'd184  : i2c_data <={ 16'h5815, 8'h00 };
		    9'd185  : i2c_data <={ 16'h5816, 8'h04 };
		    9'd186  : i2c_data <={ 16'h5817, 8'h09 };
		    9'd187  : i2c_data <={ 16'h5818, 8'h0f };
		    9'd188  : i2c_data <={ 16'h5819, 8'h08 };
		    9'd189  : i2c_data <={ 16'h581a, 8'h06 };
		    9'd190  : i2c_data <={ 16'h581b, 8'h06 };
		    9'd191  : i2c_data <={ 16'h581c, 8'h08 };
		    9'd192  : i2c_data <={ 16'h581d, 8'h0c };
		    9'd193  : i2c_data <={ 16'h581e, 8'h3f };
		    9'd194  : i2c_data <={ 16'h581f, 8'h1e };
		    9'd195  : i2c_data <={ 16'h5820, 8'h12 };
		    9'd196  : i2c_data <={ 16'h5821, 8'h13 };
		    9'd197  : i2c_data <={ 16'h5822, 8'h21 };
		    9'd198  : i2c_data <={ 16'h5823, 8'h3f };
		    9'd199  : i2c_data <={ 16'h5824, 8'h68 };
		    9'd200  : i2c_data <={ 16'h5825, 8'h28 };
		    9'd201  : i2c_data <={ 16'h5826, 8'h2c };
		    9'd202  : i2c_data <={ 16'h5827, 8'h28 };
		    9'd203  : i2c_data <={ 16'h5828, 8'h08 };
		    9'd204  : i2c_data <={ 16'h5829, 8'h48 };
		    9'd205  : i2c_data <={ 16'h582a, 8'h64 };
		    9'd206  : i2c_data <={ 16'h582b, 8'h62 };
		    9'd207  : i2c_data <={ 16'h582c, 8'h64 };
		    9'd208  : i2c_data <={ 16'h582d, 8'h28 };
		    9'd209  : i2c_data <={ 16'h582e, 8'h46 };
		    9'd210  : i2c_data <={ 16'h582f, 8'h62 };
		    9'd211  : i2c_data <={ 16'h5830, 8'h60 };
		    9'd212  : i2c_data <={ 16'h5831, 8'h62 };
		    9'd213  : i2c_data <={ 16'h5832, 8'h26 };
		    9'd214  : i2c_data <={ 16'h5833, 8'h48 };
		    9'd215  : i2c_data <={ 16'h5834, 8'h66 };
		    9'd216  : i2c_data <={ 16'h5835, 8'h44 };
		    9'd217  : i2c_data <={ 16'h5836, 8'h64 };
		    9'd218  : i2c_data <={ 16'h5837, 8'h28 };
		    9'd219  : i2c_data <={ 16'h5838, 8'h66 };
		    9'd220  : i2c_data <={ 16'h5839, 8'h48 };
		    9'd221  : i2c_data <={ 16'h583a, 8'h2c };
		    9'd222  : i2c_data <={ 16'h583b, 8'h28 };
		    9'd223  : i2c_data <={ 16'h583c, 8'h26 };
		    9'd224  : i2c_data <={ 16'h583d, 8'hae };
		    9'd225  : i2c_data <={ 16'h5025, 8'h00 };
		    9'd226  : i2c_data <={ 16'h3a0f, 8'h30 };
		    9'd227  : i2c_data <={ 16'h3a10, 8'h28 };
		    9'd228  : i2c_data <={ 16'h3a1b, 8'h30 };
		    9'd229  : i2c_data <={ 16'h3a1e, 8'h26 };
		    9'd230  : i2c_data <={ 16'h3a11, 8'h60 };
		    9'd231  : i2c_data <={ 16'h3a1f, 8'h14 };
		    9'd232  : i2c_data <={ 16'h0601, 8'h02 };
		    9'd233  : i2c_data <={ 16'h3008, 8'h42 };
		    9'd234  : i2c_data <={ 16'h3008, 8'h02 };
		    9'd235  : i2c_data <={ 16'h300e, 8'h40 };
		    9'd236  : i2c_data <={ 16'h4800, 8'h24 };
		    9'd237  : i2c_data <={ 16'h3019, 8'h70 };
		    9'd238  : i2c_data <={ 16'h3612, 8'hab };
		    9'd239  : i2c_data <={ 16'h3614, 8'h50 };
		    9'd240  : i2c_data <={ 16'h3618, 8'h04 };
		    9'd241  : i2c_data <={ 16'h3034, 8'h1a };
		    9'd242  : i2c_data <={ 16'h3035, 8'h12 };
		    9'd243  : i2c_data <={ 16'h3036, 8'h69 };
		    9'd244  : i2c_data <={ 16'h3600, 8'h08 };
		    9'd245  : i2c_data <={ 16'h3601, 8'h33 };
		    9'd246  : i2c_data <={ 16'h3708, 8'h63 };
		    9'd247  : i2c_data <={ 16'h370c, 8'hc0 };
		    //开窗寄存器
		    9'd248  : i2c_data <={ 16'h3800, 8'h01 };
		    9'd249  : i2c_data <={ 16'h3801, 8'h50 };
		    9'd250  : i2c_data <={ 16'h3802, 8'h01 };
		    9'd251  : i2c_data <={ 16'h3803, 8'hb2 };
		    9'd252  : i2c_data <={ 16'h3804, 8'h08 };
		    9'd253  : i2c_data <={ 16'h3805, 8'hef };
		    9'd254  : i2c_data <={ 16'h3806, 8'h05 };
		    9'd255  : i2c_data <={ 16'h3807, 8'hf1 };
		    9'd256  : i2c_data <={ 16'h3808, 8'h07 };
		    9'd257  : i2c_data <={ 16'h3809, 8'h80 };
		    9'd258  : i2c_data <={ 16'h380a, 8'h04 };
		    9'd259  : i2c_data <={ 16'h380b, 8'h38 };
		    9'd260  : i2c_data <={ 16'h380c, 8'h09 };
		    9'd261  : i2c_data <={ 16'h380d, 8'hc4 };
		    9'd262  : i2c_data <={ 16'h380e, 8'h04 };
		    9'd263  : i2c_data <={ 16'h380f, 8'h60 };
		    9'd264  : i2c_data <={ 16'h3810, 8'h00 };
		    9'd265  : i2c_data <={ 16'h3811, 8'h10 };
		    9'd266  : i2c_data <={ 16'h3812, 8'h00 };
		    9'd267  : i2c_data <={ 16'h3813, 8'h04 };
		    9'd268  : i2c_data <={ 16'h3814, 8'h11 };
		    9'd269  : i2c_data <={ 16'h3815, 8'h11 };
		    //.......................
		    9'd270  : i2c_data <={ 16'h4514, 8'h88 };
		    9'd271  : i2c_data <={ 16'h3a02, 8'h07 };
		    9'd272  : i2c_data <={ 16'h3a03, 8'hb0 };
		    9'd273  : i2c_data <={ 16'h3a08, 8'h01 };
		    9'd274  : i2c_data <={ 16'h3a09, 8'h50 };
		    9'd275  : i2c_data <={ 16'h3a0a, 8'h00 };
		    9'd276  : i2c_data <={ 16'h3a0b, 8'hf6 };
		    9'd277  : i2c_data <={ 16'h3a0e, 8'h06 };
		    9'd278  : i2c_data <={ 16'h3a0d, 8'h08 };
		    9'd279  : i2c_data <={ 16'h3a14, 8'h07 };
		    9'd280  : i2c_data <={ 16'h3a15, 8'hb0 };
		    9'd281  : i2c_data <={ 16'h3a18, 8'h00 };
		    9'd282  : i2c_data <={ 16'h4004, 8'h06 };
		    9'd283  : i2c_data <={ 16'h4005, 8'h18 };
		    9'd284  : i2c_data <={ 16'h4300, 8'h00 };
		    9'd285  : i2c_data <={ 16'h4202, 8'h00 };
		    9'd286  : i2c_data <={ 16'h4837, 8'h16 };	  
			default : i2c_data <= {16'h3103,8'h11}; 
		endcase
	end
end
									 
endmodule							 
									 
									 
									 