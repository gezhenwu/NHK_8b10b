--! This file is part of the altiroc emulator
--! Copyright (C) 2001-2022 CERN for the benefit of the ATLAS collaboration.
--! Authors:
--!               Frans Schreuder
--! 
--!   Licensed under the Apache License, Version 2.0 (the "License");
--!   you may not use this file except in compliance with the License.
--!   You may obtain a copy of the License at
--!
--!       http://www.apache.org/licenses/LICENSE-2.0
--!
--!   Unless required by applicable law or agreed to in writing, software
--!   distributed under the License is distributed on an "AS IS" BASIS,
--!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--!   See the License for the specific language governing permissions and
--!   limitations under the License.
library IEEE;
use IEEE.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
library XPM;
use XPM.vcomponents.all;

entity top is
port (
    LPGBT_HARD_RSTB : in std_logic;  -- From lpGBT GPIO
    LPGBT_CLK40M_P  : in std_logic;  -- 40MHz from lpGBT ECLK
    LPGBT_CLK40M_N  : in std_logic;
    --FAST_CMD_P      : in std_logic;  -- From Timing lpGBT Elink
    --FAST_CMD_N      : in std_logic;
    TIMING_DOUT_P   : out std_logic_vector(1 downto 0);  -- To Timing lpGBT Elink
    TIMING_DOUT_N   : out std_logic_vector(1 downto 0);
    LUMI_DOUT_P     : out std_logic_vector(1 downto 0);  -- To Lumi lpGBT Elink
    LUMI_DOUT_N     : out std_logic_vector(1 downto 0);
    --I2C_ADDR        : in std_logic_vector(3 downto 1);   -- Config by PEB
    --I2C_SCL         : in std_logic;                      -- From Timing lpGBT I2C master
    --I2C_SDA         : inout  std_logic;
    -- Test
    REFCLK_P: in std_logic;        -- Local OSC, 200MHz
    REFCLK_N: in std_logic
    --DIPSW:    in std_logic_vector(2 downto 0);        -- Switch SW1
    --TESTPIN: inout std_logic_vector(1 downto 0);          -- Connector J1
    --TP: out std_logic_vector(2 downto 1)                -- 
);
end entity top;

architecture rtl of top is

    signal reset: std_logic;
    signal clk_wiz_reset, locked: std_logic;
    signal clk160: std_logic;
    signal clk200, clk200_ibuf: std_logic;
    signal data_10b, data_10b_inv: std_logic_vector(9 downto 0);
    signal data_8b: std_logic_vector(7 downto 0);
    signal CharIsK: std_logic;
    signal tready: std_logic;
    signal psen, psincdec, psdone: std_logic;
    
    constant Kchar_comma  : std_logic_vector (7 downto 0) := "10111100"; -- K28.5
    constant Kchar_eop    : std_logic_vector (7 downto 0) := "11011100"; -- K28.6
    constant Kchar_sop    : std_logic_vector (7 downto 0) := "00111100"; -- K28.1
           
    
    component clk_wiz_0
    port
     (-- Clock in ports
      -- Clock out ports
      clk160          : out    std_logic;
      -- Dynamic phase shift ports
      psclk             : in     std_logic;
      psen              : in     std_logic;
      psincdec          : in     std_logic;
      psdone            : out    std_logic;
      -- Status and control signals
      reset             : in     std_logic;
      locked            : out    std_logic;
      clk_in1_p         : in     std_logic;
      clk_in1_n         : in     std_logic
     );
    end component;
    
    COMPONENT vio_0
    PORT (
        clk : IN STD_LOGIC;
        probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
      );
    END COMPONENT;
begin

clk200_buf: IBUFDS
port map(
    I => REFCLK_P,
    IB => REFCLK_N,
    O => clk200_ibuf
);

clk200_bufg: BUFG
port map(
    I => clk200_ibuf,
    O => clk200
);

clk0 : clk_wiz_0
   port map ( 
  -- Clock out ports  
   clk160 => clk160,
   psclk => clk200,
   psen => psen,
   psincdec => psincdec,
   psdone => psdone,
  -- Status and control signals                
   reset => clk_wiz_reset,
   locked => locked,
   -- Clock in ports
   clk_in1_p => LPGBT_CLK40M_P,
   clk_in1_n => LPGBT_CLK40M_N
 );
 
vio0 : vio_0
  PORT MAP (
    clk => clk200,
    probe_in0(0) => psdone,
    probe_out0(0) => psen,
    probe_out1(0) => psincdec
  );


    clk_wiz_reset <= not LPGBT_HARD_RSTB;
    reset <= not locked;
 
    
     serT0: entity work.oserdes_10b
      Port map(
      din => data_10b,
      serial_out_p => TIMING_DOUT_P(0),
      serial_out_n => TIMING_DOUT_N(0),
      reset  => reset,
      tready => tready,
      clk160 => clk160);

     serT1: entity work.oserdes_10b
      Port map(
      din => data_10b_inv,
      serial_out_p => TIMING_DOUT_N(1),
      serial_out_n => TIMING_DOUT_P(1),
      reset  => reset,
      tready => open,
      clk160 => clk160);
    
    
     serL0: entity work.oserdes_10b
      Port map(
      din => data_10b_inv,
      serial_out_p => LUMI_DOUT_N(0),
      serial_out_n => LUMI_DOUT_P(0),
      reset  => reset,
      tready => open,
      clk160 => clk160);

     serL1: entity work.oserdes_10b
      Port map(
      din => data_10b,
      serial_out_p => LUMI_DOUT_P(1),
      serial_out_n => LUMI_DOUT_N(1),
      reset  => reset,
      tready => open,
      clk160 => clk160);
   
    
datagen: process(clk160)
    variable cnt: integer range 0 to 31;
begin
    if rising_edge(clk160) then
        if reset = '1' then
            cnt := 0;
            data_8b <= Kchar_comma;
            CharIsK <= '1';
        else
            CharIsK <= '0';
            case cnt is
                when 0 to 21 => data_8b <= Kchar_comma;
                                CharIsK <= '1';
                when 22 =>      data_8b <=  Kchar_sop;
                                CharIsK <= '1';
                when 23 =>      data_8b <=  x"00";
                when 24 =>      data_8b <=  x"01";
                when 25 =>      data_8b <=  x"02";
                when 26 =>      data_8b <=  x"03";
                when 27 =>      data_8b <=  x"04";
                when 28 =>      data_8b <=  x"05";
                when 29 =>      data_8b <=  x"06";
                when 30 =>      data_8b <=  x"07";
                when 31 =>      data_8b <=  Kchar_eop;
                                CharIsK <= '1';
                when others =>  data_8b <= Kchar_comma;
                                CharIsK <= '1';
            end case;
            if tready = '1' then
                if cnt /= 31 then
                    cnt := cnt + 1;
                else
                    cnt := 0;
                end if;
            end if;
        end if;
    end if;
end process;

enc0: entity work.enc_8b10b      
    port map( 
        reset => reset,
        clk => clk160,
        ena => tready,
        KI => CharIsK, 
        datain => data_8b,
        dataout => data_10b
        );

data_10b_inv <= not data_10b;

end architecture rtl;
