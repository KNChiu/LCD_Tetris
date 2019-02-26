library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
-------------------------------------------------
entity LCM_PIC is
	port(	
			CK,CK_10K:in std_logic;									--輸入時脈
			RS,RW,E:buffer std_logic;
			DB,DEBUG:buffer std_logic_vector(7 downto 0);
			SEGRAM:in std_logic_vector(0 to 319);
			LCM_WORD_IN_1, LCM_WORD_IN_2, LCM_WORD_IN_3 ,LCM_WORD_IN_4 ,LCM_WORD_IN_5 ,LCM_WORD_IN_6 ,
			LCM_WORD_IN_7, LCM_WORD_IN_8, LCM_WORD_IN_9 ,LCM_WORD_IN_10,LCM_WORD_IN_11,LCM_WORD_IN_12,
			LCM_WORD_IN_13,LCM_WORD_IN_14,LCM_WORD_IN_15,LCM_WORD_IN_16,LCM_WORD_IN_17,LCM_WORD_IN_18,
			LCM_WORD_IN_19,LCM_WORD_IN_20,LCM_WORD_IN_21,LCM_WORD_IN_22,LCM_WORD_IN_23,LCM_WORD_IN_24:in std_logic_vector(7 downto 0)
			);
end LCM_PIC;			
-------------------------------------------------
architecture A of LCM_PIC is
signal CK_DELAY,CK_2_DELAY,DELAY,DELAY_1,DELAY_2,DELAY_3:integer range 0 to 50000;
signal LCMS,BI,ES :integer range 0 to 10;
type BOOTRAM is array(0 to 5)of std_logic_vector(7 downto 0);
constant BOOT:BOOTRAM:=(										--LCD 開機設定
						"00110000",
						"00111000", --N=1:2 LINE F=0: 5X8
						"00001000",
						"00000001",
						"00000110",
						"00001100"
						);
type WORDRAM is array(0 to 7)of std_logic_vector(0 to 39);		--自建字型暫存記憶體
signal WORD:WORDRAM;

signal WI,RI,WJ:integer range 0 to 16;							--
signal L_J:integer range 0 to 4;
signal L_I:integer range 0 to 1;

signal word_cnt:integer range 1 to 32;
type LCM_WORD_RAM is array(1 to 24)of std_logic_vector(7 downto 0);		--自建字型暫存記憶體
signal LCM_WORD:LCM_WORD_RAM;
------------------------------------------------
--signal SEGRAM:std_logic_vector(0 to 319);						--LCD顯示螢幕記憶體
-------------------------------------------------
begin
process(CK)
begin

	LCM_WORD( 1) <= LCM_WORD_IN_1;	LCM_WORD(13) <= LCM_WORD_IN_13;--輸入要顯示的文字
	LCM_WORD( 2) <= LCM_WORD_IN_2;	LCM_WORD(14) <= LCM_WORD_IN_14;
	LCM_WORD( 3) <= LCM_WORD_IN_3;	LCM_WORD(15) <= LCM_WORD_IN_15;
	LCM_WORD( 4) <= LCM_WORD_IN_4;	LCM_WORD(16) <= LCM_WORD_IN_16;
	LCM_WORD( 5) <= LCM_WORD_IN_5;	LCM_WORD(17) <= LCM_WORD_IN_17;
	LCM_WORD( 6) <= LCM_WORD_IN_6;	LCM_WORD(18) <= LCM_WORD_IN_18;
	LCM_WORD( 7) <= LCM_WORD_IN_7;	LCM_WORD(19) <= LCM_WORD_IN_19;
	LCM_WORD( 8) <= LCM_WORD_IN_8;	LCM_WORD(20) <= LCM_WORD_IN_20;
	LCM_WORD( 9) <= LCM_WORD_IN_9;	LCM_WORD(21) <= LCM_WORD_IN_21;
	LCM_WORD(10) <= LCM_WORD_IN_10;	LCM_WORD(22) <= LCM_WORD_IN_22;
	LCM_WORD(11) <= LCM_WORD_IN_11;	LCM_WORD(23) <= LCM_WORD_IN_23;
	LCM_WORD(12) <= LCM_WORD_IN_12;	LCM_WORD(24) <= LCM_WORD_IN_24;
	if rising_edge(CK) then

	end if;
	
	if rising_edge(CK_10K) then

		case ES is												--LCD 致能附程式
			when 0=>
					case LCMS is								--LCD 主程式
						when 0=>
								if DELAY = 200 then				--delay 200ms														  
									DELAY<=0; LCMS<=1;
								else
									DELAY<=DELAY+1;
								end if;
								L_J<=0; L_I<=0; WJ<=0; WI<=0;	--變數初始化
						when 1=> 
								RS<='0'; RW<='0';
								if DELAY = 50 then				--delay 50ms
									DELAY<=0;
									if BI > 5 then				--LCD 開機程式
										LCMS<=2;
									else
										DB<=BOOT(BI); ES<=1; BI<=BI+1;										
									end if;
								else
									DELAY<=DELAY+1;
								end if;
						when 2=>
								RS<='0'; RW<='0';
								DB<="01000000"; ES<=1; LCMS<=3;	--設定自建字型位址 
						when 3=>
								RS<='1'; RW<='0';
								if WJ > 7 then					--8列
									WJ<=0; LCMS<=4;
								else
									if WI > 7 then
										WI<=0; WJ<=WJ+1;
									else						--將每列的資料寫入
										DB<="000"&WORD(WJ)((WI*5) to (WI*5+4)); ES<=1; WI<=WI+1;
									end if;
								end if;
						when 4=>
								RS<='0'; RW<='0';
								if	L_J = 3 then				--4*2個自建字型
									L_J <= 0; 
									if L_I = 0 then
										L_I <= 1; 
									else
										L_I <= 0; 
									end if;
								else
									L_J<=L_J+1;
								end if;
								DB<='1' & CONV_STD_LOGIC_VECTOR(L_I,1) & CONV_STD_LOGIC_VECTOR(L_J,6);--寫入要自建的字型的位址 
								ES<=1; LCMS<=5;
						when 5=>
								RS<='1'; RW<='0';
								if DELAY_1 = 10 then
									DELAY_1<=0;
									ES<=1; LCMS<=2; 		   --結束後跳開換下一筆			
									case (L_I*4+L_J) is		   --寫入自建字型
										when 0 => DB<="00000111"; LCMS<=6; word_cnt<=1;			      --輸入一般文字數字
										when 1 => DB<="00000000";	--	-----------------
										when 2 => DB<="00000010";	--	|	|	|	|	|
										when 3 => DB<="00000100";	--	| 7 | 5 | 3 | 1 |
										when 4 => DB<="00000110";	--	|----------------
										when 5 => DB<="00000001";	--	|	|	|	|	|
										when 6 => DB<="00000011";	--	| 6 | 4 | 2 | 0 |
										when 7 => DB<="00000101";	--	-----------------
										when others=>null;
									end case;
								else
									DELAY_1<=DELAY_1+1; 
								end if;
						when 6=>
								LCMS<=7;
								
								if word_cnt = 1 then		--第一列
									DB <= "10000100";		--4
									RS<='0'; RW<='0'; ES<=1; 
								elsif word_cnt = 13 then	--第二列
									DB <= "11000100";		--20
									RS<='0'; RW<='0'; ES<=1; 
								else
									LCMS <= 7;
								end if;
								
						when 7=>		
								RS<='1'; RW<='0';
								DB <= LCM_WORD(word_cnt); 
								ES<=1;
								
								if word_cnt > 24 then
									word_cnt <= 1; LCMS<=2;	--24個文字填滿
								else
									word_cnt <= word_cnt + 1; LCMS<=6;--換填下一格
								end if;
								
						when others=>null;
					end case;
			when 1=>E<='0';ES<=2;
			when 2=>E<='1';ES<=3;
			when 3=>E<='0';ES<=0;		
			when others=>null;
		end case;
	end if;
end process;
		
		SEG_CHANGE_A:For CHANGE_A in 0 to 3 Generate		--資料轉換演算
			SEG_CHANGE_I:For CHANGE_I in 0 to 1 Generate
				SEG_CHANGE_J:For CHANGE_J in 0 to 7 Generate
					SEG_CHANGE_K:For CHANGE_K in 0 to 4 Generate
					
						WORD(CHANGE_A * 2 + CHANGE_I)(CHANGE_J * 5 + CHANGE_K)<=SEGRAM(CHANGE_A * 80 + (CHANGE_I * 8 + CHANGE_K * 16 + CHANGE_J));
						
					end Generate SEG_CHANGE_K;
				end Generate SEG_CHANGE_J;
			end Generate SEG_CHANGE_I;
		end Generate SEG_CHANGE_A;		
		
end A;			
		