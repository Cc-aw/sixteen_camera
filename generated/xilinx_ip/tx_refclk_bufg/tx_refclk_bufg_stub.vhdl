-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
-- Date        : Thu Aug 13 16:07:11 2026
-- Host        : tsmc184 running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /mnt/data/wzr/13p/ov5645/one_ov5645/demo/4k30to1k60/rtl/ip/tx_refclk_bufg/tx_refclk_bufg_stub.vhdl
-- Design      : tx_refclk_bufg
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu13p-fhga2104-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx_refclk_bufg is
  Port ( 
    BUFG_GT_I : in STD_LOGIC_VECTOR ( 0 to 0 );
    BUFG_GT_CE : in STD_LOGIC_VECTOR ( 0 to 0 );
    BUFG_GT_CEMASK : in STD_LOGIC_VECTOR ( 0 to 0 );
    BUFG_GT_CLR : in STD_LOGIC_VECTOR ( 0 to 0 );
    BUFG_GT_CLRMASK : in STD_LOGIC_VECTOR ( 0 to 0 );
    BUFG_GT_DIV : in STD_LOGIC_VECTOR ( 2 downto 0 );
    BUFG_GT_O : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end tx_refclk_bufg;

architecture stub of tx_refclk_bufg is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "BUFG_GT_I[0:0],BUFG_GT_CE[0:0],BUFG_GT_CEMASK[0:0],BUFG_GT_CLR[0:0],BUFG_GT_CLRMASK[0:0],BUFG_GT_DIV[2:0],BUFG_GT_O[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "util_ds_buf,Vivado 2023.2";
begin
end;
