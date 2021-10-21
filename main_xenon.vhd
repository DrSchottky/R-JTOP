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
    CPU_EXT_CLK_EN : out STD_LOGIC := '0';
    CPU_RESET : inout STD_LOGIC := 'Z'
  );
end main;

architecture counter of main is

constant CNT_WIDTH : integer := 21;
constant POSTCNT_WIDTH : integer := 8;
constant ADD_WIDTH : integer := 5;

--Remember to use postbit_0 instead of postbit_1.
constant POST_20 : integer := 14;
constant POST_21 : integer := 15;
constant POST_22 : integer := 16;

-- This timing is for CB 1921 with CPU_EXT_CLK_EN downclock
--constant WIDTH_RESET_START  : integer := 298260;	--95444/95445 with STBY_CLK
--constant WIDTH_RESET_END    : integer := 2;		--1 with STBY_CLK


-- This timing is for CB 8192 with CPU_EXT_CLK_EN downclock
constant WIDTH_RESET_START  : integer := 293909;	--94052 with STBY_CLK
constant WIDTH_RESET_END    : integer := 1;			--1 with STBY_CLK


constant WIDTH_BYPASS_END   : integer := 96000;

constant TIME_RESET_START  : integer := WIDTH_RESET_START;
constant TIME_RESET_END    : integer := TIME_RESET_START+WIDTH_RESET_END;
constant TIME_BYPASS_END   : integer := TIME_RESET_END+WIDTH_BYPASS_END;

--signal add: unsigned(ADD_WIDTH - 1 downto 0) := (others => '0');
signal cnt : unsigned(CNT_WIDTH-1 downto 0);
constant post_max : integer := 20;
signal post_cnt : integer range 0 to post_max := 0;


begin

	process (POSTBIT, post_cnt) is
	begin
		if (POSTBIT'event) then
			if (CPU_RESET = '0') then
				post_cnt <= 0;
			else
				if (post_cnt < post_max) then
					post_cnt <= post_cnt + 1;
				end if;
			end if;
--			if (post_cnt = 1) then
--				if add<2**ADD_WIDTH-1 then
--					add <= add + 1;
--				else
--					add <= (others => '0');
--				end if;
--			end if;
		end if;
	end process;
	
  process(CLK, POSTBIT, CPU_RESET, post_cnt) is
 begin
    if CLK' event then
      -- main counter
      if (post_cnt < POST_21) or (post_cnt > POST_22) then
        cnt <= (others => '0');
      else
        if cnt<2**CNT_WIDTH-1 then
          cnt <= cnt + 1;
        end if;
      end if;
		     
      -- bypass
      if (post_cnt >= POST_20)  and (post_cnt < POST_22) then
        CPU_EXT_CLK_EN <= '1';
		  DBG <= '1';
      else
        CPU_EXT_CLK_EN <= '0';
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