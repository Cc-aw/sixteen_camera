-- (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.
-- IP VLNV: xilinx.com:ip:util_ds_buf:2.2
-- IP Revision: 31

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT tx_refclk_bufg
  PORT (
    BUFG_GT_I : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    BUFG_GT_CE : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    BUFG_GT_CEMASK : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    BUFG_GT_CLR : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    BUFG_GT_CLRMASK : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    BUFG_GT_DIV : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    BUFG_GT_O : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : tx_refclk_bufg
  PORT MAP (
    BUFG_GT_I => BUFG_GT_I,
    BUFG_GT_CE => BUFG_GT_CE,
    BUFG_GT_CEMASK => BUFG_GT_CEMASK,
    BUFG_GT_CLR => BUFG_GT_CLR,
    BUFG_GT_CLRMASK => BUFG_GT_CLRMASK,
    BUFG_GT_DIV => BUFG_GT_DIV,
    BUFG_GT_O => BUFG_GT_O
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file tx_refclk_bufg.vhd when simulating
-- the core, tx_refclk_bufg. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.



