--Based on GliGli's RGH1 code
--R-JTOP by DrSchottky
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
  generic (
    POST_WIDTH : integer := 7
  );
  port (
    DBG : out STD_LOGIC := '0';
    POSTBIT : in STD_LOGIC;
    CLK : in STD_LOGIC;
    CPU_PLL_BYPASS : out STD_LOGIC := '0';
    CPU_RESET : inout STD_LOGIC := 'Z'
    
  );
end main;

architecture counter of main is

constant CNT_WIDTH : integer := 21;
constant POSTCNT_WIDTH : integer := 8;

--Remember to use postbit_0 instead of postbit_1.
constant POST_20 : integer := 14;
constant POST_21 : integer := 15;
constant POST_22 : integer := 16;

--Timing values, with these i get instaboot.Always.
--Adjust them for your use case.
--Jasper: 1100757_6
--Falcon: 1148870_6

constant WIDTH_RESET_START  : integer := 1100757; 
constant WIDTH_RESET_END    : integer := 6;
constant WIDTH_BYPASS_END   : integer := 96000;

constant TIME_RESET_START  : integer := WIDTH_RESET_START;
constant TIME_RESET_END    : integer := TIME_RESET_START+WIDTH_RESET_END;
constant TIME_BYPASS_END   : integer := TIME_RESET_END+WIDTH_BYPASS_END;

signal cnt : unsigned(CNT_WIDTH-1 downto 0);
signal postcnt : unsigned(POSTCNT_WIDTH-1 downto 0);
signal pp: STD_LOGIC := '0';
signal ppp: STD_LOGIC := '0';

begin

  process(CLK, POSTBIT, CPU_RESET, postcnt) is
 begin

    
    if CLK' event then
      -- fake POST
      if (to_integer(cnt) = 0) and (CPU_RESET = '0') then
        postcnt <= (others => '0');
        pp <= '0';
        ppp <= '0';
      else
        if ((to_integer(postcnt) = POST_20) or (POSTBIT = ppp)) and ((POSTBIT xor pp) = '1') then -- detect POST changes / filter POST / don't filter glitch POST
          postcnt <= postcnt + 1;
          pp <= POSTBIT;
        else
          ppp <= POSTBIT;
        end if;
      end if; 

      -- main counter
      if (to_integer(postcnt) < POST_21) or (to_integer(postcnt) > POST_22) then
        cnt <= (others => '0');
      else
        if cnt<2**CNT_WIDTH-1 then
          cnt <= cnt + 1;
        end if;
      end if;
     
      -- bypass
      if (to_integer(postcnt) >= POST_20)  and (to_integer(postcnt) <= POST_22) and (cnt < TIME_BYPASS_END) then
        CPU_PLL_BYPASS <= '1';
        DBG <= '1';
      else
        CPU_PLL_BYPASS <= '0';
        DBG <= '0';
      end if;
      
      -- reset
      if (cnt >= TIME_RESET_START) and (cnt < TIME_RESET_END) then
        CPU_RESET <= '0';
      else
        if (cnt >= TIME_RESET_END) and (cnt < TIME_BYPASS_END) then
          CPU_RESET <= '1';
        else
          CPU_RESET <= 'Z';
        end if;
      end if;
    end if;
    
  end process;
end counter;

