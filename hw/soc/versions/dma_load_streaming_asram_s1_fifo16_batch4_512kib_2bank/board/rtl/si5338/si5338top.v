//////////////////////////////////////////////////////////////////////////////////
// Company: bochenjingxin
// Engineer: yang
// Create Date: 2025/10/16 12:35:02
// Design Name: 
// Module Name: led_stream
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Dependencies: 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module si5338top
(
    input         clk_25m,//输入25M时钟
    input         sys_rstn,
    inout         si5338_scl1, //i2c clock
    inout         si5338_sda1, //i2c data  
    inout         si5338_scl2, //i2c clock
    inout         si5338_sda2  //i2c data  
//     output        conf_done1,//配置完成
//     output        conf_done2//配置完成    
    );   
     
si5338#
    (
     .kInitFileName                  ("si5338_1.mif"),//寄存器ROM配置文件名字
     .input_clk                      (25000000                ),//输入逻辑时钟频率25M
     .i2c_address                    (7'b1110000               ),//SI5338器件地址
     .bus_clk                        (400000                   )//IIC频率400K
    )si5338_inst1
    (
     .clk                            (clk_25m),
     .reset                          (~sys_rstn),//注意模块复位是高电平有效，我们需要将外部复位取反
     .done                           (),
     .error                          (),
     .SCL                            (si5338_scl1),
     .SDA                            (si5338_sda1)
     ); 
     
     si5338#
    (
     .kInitFileName                  ("si5338_2.mif"),//寄存器ROM配置文件名字
     .input_clk                      (25000000                ),//输入逻辑时钟频率25M
     .i2c_address                    (7'b1110000               ),//SI5338器件地址
     .bus_clk                        (400000                   )//IIC频率400K
    )si5338_inst2
    (
     .clk                            (clk_25m),
     .reset                          (~sys_rstn),//注意模块复位是高电平有效，我们需要将外部复位取反
     .done                           (),
     .error                          (),
     .SCL                            (si5338_scl2),
     .SDA                            (si5338_sda2)
     ); 
    
endmodule
