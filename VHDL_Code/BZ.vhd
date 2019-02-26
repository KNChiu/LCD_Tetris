library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
-------------------------------------------------
entity BZ is
	port(	
			CK,RESET:in std_logic;									--¿é¤J®É¯ß
			BZ_OUT:buffer std_logic
			);
end BZ;			
-------------------------------------------------
architecture A of BZ is
signal BZ_CLK_CASE:integer range 0 to 5;
signal BZ_CNT,BZ_CLK,TIME_DELAY :integer range 0 to 50000000;
signal BZ_DELAY :integer range 0 to 50000000;
signal music_f :integer range 0 to 2000;
signal BZ_25M  :std_logic;
Type MUSIC is Array(0 to 6) of integer range 0 to 2000;
constant  SONG :MUSIC:=( 392,330,330,349,294,294,262
						);
--			Do	262
--			Re	294
--			Mi	330
--			Fa	349
--			So	392
--			La	440
--			Si	494
--			DO#	523
signal BEATS,M_I:integer range 0 to 19;
-------------------------------------------------
begin
process(CK)
begin
	
--	music_f <= 294;
	BEATS <= 2;
	if rising_edge(CK) then
--		if BZ_CNT = 24999999 then
--			BZ_CNT <= 0; BZ_25M <= not BZ_25M;
--		else
--			BZ_CNT <= BZ_CNT + 1;
--		end if;
		
		case BZ_CLK_CASE is
			when 0=>
					if M_I = 6 then
						M_I <= 0;
					else
						M_I <= M_I + 1;
					end if;
					music_f <= SONG(M_I); BZ_CLK_CASE <= 1;
			when 1=>
					BZ_CLK <= (25000000/music_f);
					BZ_CLK_CASE <= 2;
			when 2=>
					if TIME_DELAY = (50000000/BEATS) then
						TIME_DELAY <= 0; BZ_CLK_CASE <= 0;
						BZ_OUT <= '0';
					else
						TIME_DELAY <= TIME_DELAY + 1;
					end if;
					
					if BZ_CNT = BZ_CLK then
						BZ_CNT <= 0; BZ_OUT <= not BZ_OUT;
					else
						BZ_CNT <= BZ_CNT + 1;
					end if;
					
			when others=>null;
		end case;
				
	end if;
			
						
	
end process;
		
	
		
end A;			
		