library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
-------------------------------------------------
entity LCD_Tetris  is
	port(	
			CK,reset:in std_logic;									--輸入時脈
			R_B,L_B:in std_logic;
			RS,RW,E,BZ_OUT:buffer std_logic;						--LCM 控制線	蜂鳴器控制線
			DB,DEBUG:buffer std_logic_vector(7 downto 0)
			);
end LCD_Tetris;			
-------------------------------------------------
architecture A of LCD_Tetris is
component LCM_PIC is
   port(    														
        CK,CK_10K:in std_logic; 												--輸入時脈
		RS,RW,E:buffer std_logic;
		DB,DEBUG:buffer std_logic_vector(7 downto 0);
		SEGRAM:in std_logic_vector(0 to 319);
		LCM_WORD_IN_1, LCM_WORD_IN_2, LCM_WORD_IN_3 ,LCM_WORD_IN_4 ,LCM_WORD_IN_5 ,LCM_WORD_IN_6 ,
	    LCM_WORD_IN_7, LCM_WORD_IN_8, LCM_WORD_IN_9 ,LCM_WORD_IN_10,LCM_WORD_IN_11,LCM_WORD_IN_12,
	    LCM_WORD_IN_13,LCM_WORD_IN_14,LCM_WORD_IN_15,LCM_WORD_IN_16,LCM_WORD_IN_17,LCM_WORD_IN_18,
	    LCM_WORD_IN_19,LCM_WORD_IN_20,LCM_WORD_IN_21,LCM_WORD_IN_22,LCM_WORD_IN_23,LCM_WORD_IN_24
	    :std_logic_vector(7 downto 0)
       );
end component LCM_PIC;

component BZ is	
   port(  
		CK,RESET:in std_logic;
		BZ_OUT:buffer std_logic
		);
end component BZ;
-------------------------------------------------
signal CK_10K,CK2:std_logic;
signal CK_DELAY,CK_2_DELAY,DELAY,DELAY_1,DELAY_2,DELAY_3:integer range 0 to 50000;

--type RAM is array(0 to 2)of std_logic_vector(0 to 319);                         --OLED初始化 command 資料
--constant SEG:RAM:=(
--						X"FFFF800180018001800180018001800180018001800180018001FFFF80018001800180018001FFFF",-- 框
--						X"FFFF800183C1842188118811842180018FF1808181C18E3180018FF1802180C183018FF18001FFFF",-- CKN
--						X"FFFF8001B181B0C180018001BCC5819D80018001B9C190418001FFFF80018001800180018001FFFF" -- MOD
--						);
type RAM_PIC is array(0 to 8) of std_logic_vector(0 to 15);
constant PIC:RAM_PIC:=(
						X"0000",X"0066",X"4444",X"0464",X"0462",X"0264",X"0446",X"0226",X"FFFF"
						);

------------------------------------------------
signal SEGRAM:std_logic_vector(0 to 319);						--LCD顯示螢幕記憶體
--signal Tetris_RAM:std_logic_vector(0 to 319);
type RAM_2 is array(0 to 11)of std_logic_vector(0 to 13);
signal Tetris_RAM:RAM_2;					--12*14

signal NEXT_RAM:std_logic_vector(0 to 69);

signal LCM_WORD_IN_1, LCM_WORD_IN_2, LCM_WORD_IN_3 ,LCM_WORD_IN_4 ,LCM_WORD_IN_5 ,LCM_WORD_IN_6 ,
	   LCM_WORD_IN_7, LCM_WORD_IN_8, LCM_WORD_IN_9 ,LCM_WORD_IN_10,LCM_WORD_IN_11,LCM_WORD_IN_12,
	   LCM_WORD_IN_13,LCM_WORD_IN_14,LCM_WORD_IN_15,LCM_WORD_IN_16,LCM_WORD_IN_17,LCM_WORD_IN_18,
	   LCM_WORD_IN_19,LCM_WORD_IN_20,LCM_WORD_IN_21,LCM_WORD_IN_22,LCM_WORD_IN_23,LCM_WORD_IN_24
	   :std_logic_vector(7 downto 0);

signal BUT_DELAY:integer range 0 to 24999;
signal R_B_M,L_B_M:std_logic;

signal Tetris:integer range 0 to 5;							--主程式case
signal PIC_MAKE:integer range 0 to 5;						--畫出方塊副程式 
signal PIC_I:integer range 0 to 13;
signal SEC_DELAY:integer range 0 to 50000000;				--下降延遲時間
signal LEVEL:integer range 0 to 5;							--關卡等級
signal DOWN,RLM:integer range 0 to 14;						--下降位址變數
signal BLK:integer range 1 to 7;							--所選的方塊
signal L_B_S:std_logic;										--butten case
-------------------------------------------------
begin
process(CK)
begin
------------------------------------
	LEVEL <= 1;		--關卡
	--RLM <= 0;
	
------------------------------------
	if reset = '0' then
	elsif rising_edge(CK) then
	
		if BUT_DELAY = 24999 then
			R_B_M <= R_B;
			L_B_M <= L_B;
			BUT_DELAY <= 0;
		else
			BUT_DELAY <= BUT_DELAY + 1;
		end if;
			
		if CK_DELAY = 2500 then								--CK_1K 除頻
			CK_10K<=not CK_10K; CK_DELAY<=0; 
		else
			CK_DELAY<=CK_DELAY+1;
		end if;	
		
		case PIC_MAKE is 
			when 0=>
					case Tetris is
						when 0=>
								Tetris <= 0;
								RLM <= 0; 								--X
								DOWN <= 0;								--Y
								
								LCM_WORD_IN_1 <=X"20";LCM_WORD_IN_2 <=X"20";LCM_WORD_IN_3 <=X"4C";LCM_WORD_IN_4 <=X"65";
								LCM_WORD_IN_5 <=X"76";LCM_WORD_IN_6 <=X"65";LCM_WORD_IN_7 <=X"6C";LCM_WORD_IN_8 <=X"3A";
								LCM_WORD_IN_9 <=X"20";LCM_WORD_IN_10<=X"31";LCM_WORD_IN_11<=X"20";LCM_WORD_IN_12<=X"20"; --  Level: 1
								LCM_WORD_IN_13<=X"20";LCM_WORD_IN_14<=X"20";LCM_WORD_IN_15<=X"53";LCM_WORD_IN_16<=X"63";
								LCM_WORD_IN_17<=X"6F";LCM_WORD_IN_18<=X"72";LCM_WORD_IN_19<=X"65";LCM_WORD_IN_20<=X"3A";
								LCM_WORD_IN_21<=X"30";LCM_WORD_IN_22<=X"30";LCM_WORD_IN_23<=X"30";LCM_WORD_IN_24<=X"20"; --  Score:000
								
--								Tetris_RAM <= X"000000000000000000000000000000000000000000";							--畫面1 
								Tetris_RAM(0) <= "111111111111"; Tetris_RAM(1) <= "111111111111"; Tetris_RAM(2) <= "000000000000"; Tetris_RAM(3) <= "000000000000";
								
								NEXT_RAM <=  "0000000000000000000000000000000000000000000000000000000000000000000000";	--畫面2 
								
						when 1=>
								if SEC_DELAY = (25000000/LEVEL) then 	--下降延遲時間
									SEC_DELAY <= 0;
									if DOWN = 10 then
										DOWN <= 0;
									else
										DOWN <= DOWN + 1; 
									end if;
								else
									SEC_DELAY <= SEC_DELAY + 1;
									
--									case L_B_S is
--										when '0' =>
--													if L_B_M = '1' then
--														L_B_S <= '1';
--														RLM  <= RLM - 1;
--														PIC_MAKE <= 2;
--													end if;
--										when '1' =>
--													if L_B_M = '0' then
--														L_B_S <= '0';
--														
--													end if;
--									end case;
									
								end if;
								PIC_MAKE <= 1;						--跳至畫出方塊副程式 	
								
						when others => null;
					end case;
			when 1=>
					PIC_MAKE <= 0;
--					if ( (Tetris_RAM( (3 + DOWN) * 12 +RLM + 4)and Tetris_RAM((4 + DOWN) * 12 +RLM + 4) ) or 
--					     (Tetris_RAM( (3 + DOWN) * 12 +RLM + 5)and Tetris_RAM((4 + DOWN) * 12 +RLM + 5) ) or
--					     (Tetris_RAM( (3 + DOWN) * 12 +RLM + 6)and Tetris_RAM((4 + DOWN) * 12 +RLM + 6) ) or 
--					     (Tetris_RAM( (3 + DOWN) * 12 +RLM + 7)and Tetris_RAM((4 + DOWN) * 12 +RLM + 7) ) ) = '1'
--					then
--						DOWN <= 0;									--停止下降
--						BLK <= BLK + 1;
--					else
--						Tetris_RAM(((0 + DOWN) * 12 +RLM + 4) to ((0 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(0 to 3);
--						Tetris_RAM(((1 + DOWN) * 12 +RLM + 4) to ((1 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(4 to 7);
--						Tetris_RAM(((2 + DOWN) * 12 +RLM + 4) to ((2 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(8 to 11);
--						Tetris_RAM(((3 + DOWN) * 12 +RLM + 4) to ((3 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(12 to 15);
--						Tetris_RAM(((-1 + DOWN) * 12 +RLM + 4) to ((-1 + DOWN) * 12 +RLM + 7)) <= "0000";
--					end if;
			when 2=>
					PIC_MAKE <= 0;
--						Tetris_RAM(((0 + DOWN) * 12 +RLM + 4) to ((0 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(0 to 3);
--						Tetris_RAM(((1 + DOWN) * 12 +RLM + 4) to ((1 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(4 to 7);
--						Tetris_RAM(((2 + DOWN) * 12 +RLM + 4) to ((2 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(8 to 11);
--						Tetris_RAM(((3 + DOWN) * 12 +RLM + 4) to ((3 + DOWN) * 12 +RLM + 7)) <= PIC(BLK)(12 to 15);
----						Tetris_RAM(((-1 + DOWN) * 12 +RLM + 4) to ((-1 + DOWN) * 12 +RLM + 7)) <= "0000";
			when others=>null;
		end case;
		
	  
--		Tetris_RAM <= X"000000000060060000000000000610F13E53FFFFBF";							--畫面1 DEMO
--		NEXT_RAM <=  "0000000000011000110000000010000110000100000000100001000011000000000000";	--畫面2 DEMO
--
--		LCM_WORD_IN_1 <=X"20";LCM_WORD_IN_2 <=X"20";LCM_WORD_IN_3 <=X"4C";LCM_WORD_IN_4 <=X"65";
--		LCM_WORD_IN_5 <=X"76";LCM_WORD_IN_6 <=X"65";LCM_WORD_IN_7 <=X"6C";LCM_WORD_IN_8 <=X"3A";
--		LCM_WORD_IN_9 <=X"20";LCM_WORD_IN_10<=X"32";LCM_WORD_IN_11<=X"20";LCM_WORD_IN_12<=X"20"; --  Level: 2
--		LCM_WORD_IN_13<=X"20";LCM_WORD_IN_14<=X"20";LCM_WORD_IN_15<=X"53";LCM_WORD_IN_16<=X"63";
--		LCM_WORD_IN_17<=X"6F";LCM_WORD_IN_18<=X"72";LCM_WORD_IN_19<=X"65";LCM_WORD_IN_20<=X"3A";
--		LCM_WORD_IN_21<=X"31";LCM_WORD_IN_22<=X"35";LCM_WORD_IN_23<=X"30";LCM_WORD_IN_24<=X"20"; --  Score:150		
					
			
		
	end if;

end process;
--							-------------- 4
--							|       |    |
--							|	    | 畫 |
--							| 畫面1 | 面 |
--							|		|  2 |
--							|	    |    |
--							-------------- 5
--					外框    1      2   3
															
		SEGRAM(0 to 15) <= X"FFFF";							--外框1 
		SEGRAM(208 to 223) <= X"FFFF"; 						--外框2
		SEGRAM(304 to 319) <= X"FFFF"; 						--外框3
		
		SEG_CHANGE_I:For CHANGE_I in 1 to 18 Generate		
			SEGRAM(CHANGE_I*16)<='1';						--外框4
			SEGRAM(((CHANGE_I + 1) * 16) - 1)<='1';			--外框5
		end Generate SEG_CHANGE_I;
		
		SEG_CHANGE_J:For J in 0 to 11 Generate				--畫面1轉換
			SEG_CHANGE_T:For T in 0 to 13 Generate
				SEGRAM((17 + (J * 16) + T)) <= Tetris_RAM(J)(T);
			end Generate SEG_CHANGE_T;										
		end Generate SEG_CHANGE_J;
		
		SEG_CHANGE_K:For K in 0 to 4 Generate				--畫面2轉換
			SEGRAM((225 + K * 16)to (238 + K * 16)) <= NEXT_RAM(  0+K) & NEXT_RAM(  5+K) & NEXT_RAM( 10+K) & NEXT_RAM( 15+K)
													  &NEXT_RAM( 20+K) & NEXT_RAM( 25+K) & NEXT_RAM( 30+K) & NEXT_RAM( 35+K)
													  &NEXT_RAM( 40+K) & NEXT_RAM( 45+K) & NEXT_RAM( 50+K) & NEXT_RAM( 55+K)
													  &NEXT_RAM( 60+K) & NEXT_RAM( 65+K);
		end Generate SEG_CHANGE_K;
		
	u0:LCM_PIC
	port map(      
			CK => CK,
			CK_10K => CK_10K,
			RS => RS,
			RW => RW,
			E => E,
			DB => DB,
			DEBUG => DEBUG,
			SEGRAM => SEGRAM,
			LCM_WORD_IN_1 =>LCM_WORD_IN_1, LCM_WORD_IN_2 =>LCM_WORD_IN_2, LCM_WORD_IN_3 =>LCM_WORD_IN_3, LCM_WORD_IN_4 =>LCM_WORD_IN_4,
			LCM_WORD_IN_5 =>LCM_WORD_IN_5, LCM_WORD_IN_6 =>LCM_WORD_IN_6, LCM_WORD_IN_7 =>LCM_WORD_IN_7, LCM_WORD_IN_8 =>LCM_WORD_IN_8,
			LCM_WORD_IN_9 =>LCM_WORD_IN_9, LCM_WORD_IN_10 =>LCM_WORD_IN_10, LCM_WORD_IN_11 =>LCM_WORD_IN_11, LCM_WORD_IN_12 =>LCM_WORD_IN_12,
			LCM_WORD_IN_13 =>LCM_WORD_IN_13, LCM_WORD_IN_14 =>LCM_WORD_IN_14, LCM_WORD_IN_15 =>LCM_WORD_IN_15, LCM_WORD_IN_16 =>LCM_WORD_IN_16,
			LCM_WORD_IN_17 =>LCM_WORD_IN_17, LCM_WORD_IN_18 =>LCM_WORD_IN_18, LCM_WORD_IN_19 =>LCM_WORD_IN_19, LCM_WORD_IN_20 =>LCM_WORD_IN_20, 
			LCM_WORD_IN_21 =>LCM_WORD_IN_21, LCM_WORD_IN_22 =>LCM_WORD_IN_22, LCM_WORD_IN_23 =>LCM_WORD_IN_23, LCM_WORD_IN_24 =>LCM_WORD_IN_24
            );
    u1:BZ
    port map(
			CK => CK,
			RESET => RESET,
			BZ_OUT => BZ_OUT
			);
end A;			
		