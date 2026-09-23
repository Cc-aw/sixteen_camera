-- (c) Copyright 2023 Advanced Micro Devices, Inc. All rights reserved.
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
------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity nidru_20_wrapper is
  generic (

    -- S_MAX              : in std_logic_vector (9 downto 0):= "1111111111";  -- max number of extracted bits, not coded
    S_MAX   : in integer range 1 to 10          := 10;  -- max number of extracted bits, decimal
    MASK_CG : in std_logic_vector (15 downto 0) := "1111111111111111";  -- place same number of LSb zeros

    MASK_PD : in std_logic_vector (15 downto 0) := "1111111111111111";  -- place same number of LSb zeros

    MASK_VCO : in std_logic_vector (36 downto 0) := "1111111111111111111111111111111111111";  -- plase same number of LSb zeros

    -- EN_INTEG           : in std_logic := '1';    -- by default 1
    -- PH_EST_DIS         : in std_logic := '0';    -- by defauls 0
    WDT_OUT : in integer range 2 to 40 := 10  -- output width

    );

  port (
    DT_IN    : in std_logic_vector (19 downto 0);
    CENTER_F : in std_logic_vector (36 downto 0);
    EN       : in std_logic;
    G1       : in std_logic_vector(4 downto 0);
    G1_P     : in std_logic_vector(4 downto 0);
    G2       : in std_logic_vector(4 downto 0);
    CLK      : in std_logic;

    PH_OUT     : out std_logic_vector(20 downto 0);
    INTEG      : out std_logic_vector(31 downto 0);
    DIRECT     : out std_logic_vector(31 downto 0);
    CTRL       : out std_logic_vector (31 downto 0);
    AL_PPM     : out std_logic;
    -- PL                 : in   std_logic;   --default 0
    -- PHASE_IN           : in   std_logic_vector(31 downto 0);
    RST        : in  std_logic;         --ative high
    RST_FREQ   : in  std_logic;         -- active high
    EN_INTEG   : in  std_logic;         -- by default 1
    PH_EST_DIS : in  std_logic;         -- by defauls 0
    VER        : out std_logic_vector(7 downto 0);
    RECCLK     : out std_logic_vector(19 downto 0);
    SAMV       : out std_logic_vector(3 downto 0);
    SAM        : out std_logic_vector(9 downto 0);
    EN_OUT     : out std_logic;
    DOUT       : out std_logic_vector((WDT_OUT -1) downto 0)
    );

end nidru_20_wrapper;

architecture Behavioral of nidru_20_wrapper is

  component dru
    generic (

      -- S_MAX              : in std_logic_vector (9 downto 0):= "0000000011";  -- max number of extracted bits, not coded
      S_MAX        : in integer range 1 to 10          := 10;  -- max number of extracted bits, decimal
      MASK_CG      : in std_logic_vector (15 downto 0) := "1111111111110000";  -- place same number of LSb zeros
      MASK_PD      : in std_logic_vector (15 downto 0) := "1111111111110000";  -- place same number of LSb zeros
      MASK_VCO     : in std_logic_vector (36 downto 0) := "1111111111111111111111111111111110000";  -- plase same number of LSb zeros
      -- EN_INTEG           : in std_logic := '1';    -- by default 1
      EN_ADV_COMPR : in boolean                        := false  -- by default 0. when set to 1 activates the advanced compressor
      -- PH_EST_DIS         : in std_logic := '0'    -- by defauls 0


      );
    port(
      DT_IN      : in  std_logic_vector(19 downto 0);
      CENTER_F   : in  std_logic_vector(36 downto 0);
      EN         : in  std_logic;
      G1         : in  std_logic_vector(4 downto 0);
      G1_P       : in  std_logic_vector(4 downto 0);
      G2         : in  std_logic_vector(4 downto 0);
      CLK        : in  std_logic;
      PL         : in  std_logic;
      PHASE_IN   : in  std_logic_vector(31 downto 0);
      RST        : in  std_logic;
      RST_FREQ   : in  std_logic;
      EN_INTEG   : in  std_logic := '1';  -- by default 1
      PH_EST_DIS : in  std_logic := '0';  -- by defauls 0              
      PH_OUT     : out std_logic_vector(20 downto 0);
      INTEG      : out std_logic_vector(31 downto 0);
      DIRECT     : out std_logic_vector(31 downto 0);
      CTRL       : out std_logic_vector(31 downto 0);
      AL_PPM     : out std_logic;

      RECCLK : out std_logic_vector(19 downto 0);
      SAMV   : out std_logic_vector(3 downto 0);
      SAM    : out std_logic_vector(9 downto 0);

      VER : out std_logic_vector(7 downto 0)
      );
  end component;

  component bs_flex
    generic (
      WDT_IN  : in integer range 2 to 40 := 10;
      WDT_OUT : in integer range 2 to 40 := 10;

      S_MAX : in integer range 2 to 31 := 10
      );
    port (
      CLK    : in  std_logic;
      RST    : in  std_logic;
      DIN    : in  std_logic_vector((WDT_IN - 1) downto 0);
      EN     : in  std_logic;
      EN_IN  : in  std_logic_vector(4 downto 0);
      EN_OUT : out std_logic;
      DOUT   : out std_logic_vector((WDT_OUT-1) downto 0)
      );
  end component;

  signal samv_int_1 : std_logic_vector (4 downto 0) := "00000";
  signal sam_int    : std_logic_vector (9 downto 0) := "0000000000";

--	attribute MARK_DEBUG : string;
--	attribute MARK_DEBUG of sam_int : signal is "TRUE";
--	attribute MARK_DEBUG of samv_int_1 : signal is "TRUE";

begin
  Inst_dru : dru
    generic map(
      S_MAX 	   => S_MAX,
      MASK_CG      => MASK_CG,
      MASK_PD      => MASK_PD,
      EN_ADV_COMPR => true,
      MASK_VCO     => MASK_VCO
      )
    port map(
      DT_IN      => DT_IN,
      CENTER_F   => CENTER_F,
      EN         => EN,
      G1         => G1,
      G1_P       => G1_P,
      G2         => G2,
      CLK        => CLK,
      PH_OUT     => PH_OUT,
      INTEG      => INTEG,
      DIRECT     => DIRECT,
      CTRL       => CTRL,
      AL_PPM     => AL_PPM,
      PL         => '0',
      PHASE_IN   => (others => '0'),
      RST        => RST,
      RST_FREQ   => RST_FREQ,
      EN_INTEG   => EN_INTEG,
      PH_EST_DIS => PH_EST_DIS,
      VER        => VER,
      RECCLK     => RECCLK,
      SAMV       => samv_int_1(3 downto 0),
      SAM        => sam_int
      );

  SAMV <= samv_int_1(3 downto 0);
  SAM  <= sam_int;



  bs_flex_dru : bs_flex
    generic map(
      WDT_IN  => 10,
      WDT_OUT => WDT_OUT,
      S_MAX   => S_MAX
      )
    port map(
      CLK    => CLK,
      RST    => RST,
      DIN    => sam_int,
      EN     => EN,
      EN_IN  => samv_int_1,
      EN_OUT => EN_OUT,
      DOUT   => DOUT
      );


end Behavioral;
