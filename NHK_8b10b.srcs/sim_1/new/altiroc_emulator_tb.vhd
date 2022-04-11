----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/06/2022 09:15:16 AM
-- Design Name: 
-- Module Name: altiroc_emulator_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity altiroc_emulator_tb is
--  Port ( );
end altiroc_emulator_tb;

architecture Behavioral of altiroc_emulator_tb is

signal resetn, clk40, clk40p, clk40n: std_logic;
signal timing_dout_p, timing_dout_n, lumi_dout_p, lumi_dout_n: std_logic_vector(1 downto 0);
constant clk40_period: time := 25ns;
begin

clk40_proc: process
begin
    clk40 <= '1';
    wait for clk40_period/2;
    clk40 <= '0';
    wait for clk40_period/2;
end process;

clk40p <= clk40;
clk40n <= not clk40;

reset_proc: process(clk40)
    variable cnt: integer range 0 to 255 := 0;
begin
    if rising_edge(clk40) then
        if cnt < 255 then
            resetn <= '0';
            cnt := cnt + 1;
        else
            resetn <= '1';
        end if;
    end if;
end process;

uut: entity work.top 
port map(
    LPGBT_HARD_RSTB => resetn, --: in std_logic;  -- From lpGBT GPIO
    LPGBT_CLK40M_P  => clk40p, --: in std_logic;  -- 40MHz from lpGBT ECLK
    LPGBT_CLK40M_N  => clk40n, --: in std_logic;
    --FAST_CMD_P      : in std_logic;  -- From Timing lpGBT Elink
    --FAST_CMD_N      : in std_logic;
    TIMING_DOUT_P   => timing_dout_p, --: out std_logic_vector(1 downto 0);  -- To Timing lpGBT Elink
    TIMING_DOUT_N   => timing_dout_n, --: out std_logic_vector(1 downto 0);
    LUMI_DOUT_P     => lumi_dout_p, --: out std_logic_vector(1 downto 0);  -- To Lumi lpGBT Elink
    LUMI_DOUT_N     => lumi_dout_n --: out std_logic_vector(1 downto 0)
    --I2C_ADDR        : in std_logic_vector(3 downto 1);   -- Config by PEB
    --I2C_SCL         : in std_logic;                      -- From Timing lpGBT I2C master
    --I2C_SDA         : inout  std_logic;
    -- Test
    --REFCLK_P: in std_logic;        -- Local OSC, 200MHz
    --REFCLK_N: in std_logic;
    --DIPSW:    in std_logic_vector(2 downto 0);        -- Switch SW1
    --TESTPIN: inout std_logic_vector(1 downto 0);          -- Connector J1
    --TP: out std_logic_vector(2 downto 1)                -- 
);

end Behavioral;
