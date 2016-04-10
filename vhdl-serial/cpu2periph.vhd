----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:44:29 03/03/2016 
-- Design Name: 
-- Module Name:    cpu2periph - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu2periph is
    Port ( clk_cpu : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           cpu_write : in  STD_LOGIC;
           cpu_data : in  STD_LOGIC_VECTOR (3 downto 0);
           --established : in  STD_LOGIC;
			  buffok : in  STD_LOGIC;
           setbuff : out  STD_LOGIC;
           pcbuff : out  STD_LOGIC_VECTOR (7 downto 0);
           cpu_ready : out  STD_LOGIC;
			  
			  debug : out std_logic);
end cpu2periph;

architecture Behavioral of cpu2periph is
	signal buff : std_logic_vector(pcbuff'range);
	
	type PERIPHSTATE is (WAIT4EMPTYBUFF, WAIT4MSB, RXMSB, WAIT4LSB, RXLSB);
	signal CurrState : PERIPHSTATE;
	
	signal dbg : std_logic;
begin
	process(clk_cpu, reset)
	begin
		if reset = '1' then
			CurrState <= WAIT4EMPTYBUFF;
			buff <= (others => '0');
			pcbuff <= (others => '0');
			cpu_ready <= '0';
			dbg <= '0';
		elsif rising_edge(clk_cpu) then
			case CurrState is
				when WAIT4EMPTYBUFF =>	--wait until the BUFFOK flag is cleared, which hopefully happens fast enough, and connection is established
					setbuff <= '0';
					if buffok = '0' then --and established = '1' then
						CurrState <= WAIT4MSB;
					end if;
					
				when WAIT4MSB =>	--wait for CPU to request a write
					if cpu_write = '1' then
						cpu_ready <= '1';
						CurrState <= RXMSB;
					end if;
					
				when RXMSB =>	--meh, quite a useless state
				--	CurrState <= STOPMSB;
				
				--when STOPMSB =>	--set ready low, and while cpu_write is still high, copy its data to the buffer
				--	cpu_ready <= '0';
					if cpu_write = '1' then
						buff(7 downto 4) <= cpu_data;
					else
						cpu_ready <= '0';
						CurrState <= WAIT4LSB;
					end if;
					
				when WAIT4LSB =>	--wait for CPU to request a write
					if cpu_write = '1' then
						cpu_ready <= '1';
						CurrState <= RXLSB;
					end if;
					
				when RXLSB =>	--meh, quite a useless state
				--	CurrState <= STOPLSB;
				
				--when STOPLSB =>	--set ready low, and while cpu_write is still high, copy its data to the buffer
				--	cpu_ready <= '0';
					if cpu_write = '1' then
						buff(3 downto 0) <= cpu_data;
					else
						--Our data is ready, put it into the PCBUFF and set the BUFFOK flag
						cpu_ready <= '0';
						pcbuff <= buff;
						setbuff <= '1';
						CurrState <= WAIT4EMPTYBUFF;
					end if;
					
					dbg <= not dbg;
			end case;
		end if;
	end process;
	
	debug <= dbg;
end Behavioral;

