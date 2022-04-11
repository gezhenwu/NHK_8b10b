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
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity oserdes_10b is
  Port (
  din: in std_logic_vector(9 downto 0);
  serial_out_p: out std_logic;
  serial_out_n: out std_logic;
  reset: in std_logic;
  tready: out std_logic;
  --clk32: in std_logic;
  clk160: in std_logic);
end oserdes_10b;

architecture Behavioral of oserdes_10b is
    signal shiftreg: std_logic_vector(9 downto 0);
    signal cnt: integer range 0 to 7;
    signal serial_out: std_logic;
begin


   shiftproc: process(clk160)
   begin
       if rising_edge(clk160) then
           if reset = '1' then
               cnt <= 0;
               shiftreg <= (others => '0');
               tready <= '0';
           else
               if cnt = 4 then
                   cnt <= 0;
                   tready <= '1';
                   shiftreg <= din;
               else
                   shiftreg <= shiftreg(7 downto 0) & "00";
                   cnt <= cnt + 1;
                   tready <= '0';
               end if;
           end if;
       end if;
   end process;
   
   ODDR_inst : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => serial_out,   -- 1-bit DDR output
      C => clk160,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => shiftreg(9),  -- 1-bit data input (positive edge)
      D2 => shiftreg(8),  -- 1-bit data input (negative edge)
      R => reset,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
   
   
   obuf0: OBUFDS port map(
     I => serial_out,
     O => serial_out_p,
     OB => serial_out_n
   );

end Behavioral;

--! The OSERDESE2 in 10b mode did not play nice, I may have done something wrong. Switched to ODDR instead.
--   OSERDESE2_inst_master : OSERDESE2
--   generic map (
--      DATA_RATE_OQ => "DDR",   -- DDR, SDR
--      DATA_RATE_TQ => "DDR",   -- DDR, BUF, SDR
--      DATA_WIDTH => 10,         -- Parallel data width (2-8,10,14)
--      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
--      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
--      SERDES_MODE => "MASTER", -- MASTER, SLAVE
--      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
--      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
--      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
--      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
--      TRISTATE_WIDTH => 1      -- 3-state converter width (1,4)
--   )
--   port map (
--      OFB => open,             -- 1-bit output: Feedback path for data
--      OQ => serial_out,               -- 1-bit output: Data path output
--      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
--      SHIFTOUT1 => open,
--      SHIFTOUT2 => open,
--      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
--      TFB => open,             -- 1-bit output: 3-state control
--      TQ => open,               -- 1-bit output: 3-state control
--      CLK => clk160,             -- 1-bit input: High speed clock
--      CLKDIV => clk32,       -- 1-bit input: Divided clock
--      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
--      D1 => din(9),
--      D2 => din(8),
--      D3 => din(7),
--      D4 => din(6),
--      D5 => din(5),
--      D6 => din(4),
--      D7 => din(3),
--      D8 => din(2),
--      OCE => '1',          -- 1-bit input: Output data clock enable
--      RST => reset,             -- 1-bit input: Reset
--      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
--      SHIFTIN1 => SHIFT1,
--      SHIFTIN2 => SHIFT2,
--      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
--      T1 => '0',
--      T2 => '0',
--      T3 => '0',
--      T4 => '0',
--      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
--      TCE => '1'              -- 1-bit input: 3-state clock enable
--   );

--   OSERDESE2_inst_slave : OSERDESE2
--   generic map (
--      DATA_RATE_OQ => "DDR",   -- DDR, SDR
--      DATA_RATE_TQ => "DDR",   -- DDR, BUF, SDR
--      DATA_WIDTH => 10,         -- Parallel data width (2-8,10,14)
--      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
--      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
--      SERDES_MODE => "SLAVE", -- MASTER, SLAVE
--      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
--      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
--      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
--      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
--      TRISTATE_WIDTH => 1      -- 3-state converter width (1,4)
--   )
--   port map (
--      OFB => open,             -- 1-bit output: Feedback path for data
--      OQ => open,               -- 1-bit output: Data path output
--      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
--      SHIFTOUT1 => shift1,
--      SHIFTOUT2 => shift2,
--      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
--      TFB => open,             -- 1-bit output: 3-state control
--      TQ => open,               -- 1-bit output: 3-state control
--      CLK => clk160,             -- 1-bit input: High speed clock
--      CLKDIV => clk32,       -- 1-bit input: Divided clock
--      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
--      D1 => '0',
--      D2 => '0',
--      D3 => din(1),
--      D4 => din(0),
--      D5 => '0',
--      D6 => '0',
--      D7 => '0',
--      D8 => '0',
--      OCE => '1',          -- 1-bit input: Output data clock enable
--      RST => reset,             -- 1-bit input: Reset
--      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
--      SHIFTIN1 => '0',
--      SHIFTIN2 => '0',
--      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
--      T1 => '0',
--      T2 => '0',
--      T3 => '0',
--      T4 => '0',
--      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
--      TCE => '1'   
--   );
