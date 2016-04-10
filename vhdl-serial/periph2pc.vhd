----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:15:42 02/22/2016 
-- Design Name: 
-- Module Name:    periph2pc - Behavioral 
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

entity periph2pc is
    Port ( clk_uart : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  --rs232_dtr : in  STD_LOGIC;
           buff : in  STD_LOGIC_VECTOR (7 downto 0);
           buffok : in  STD_LOGIC;
			  clrbuff : out  STD_LOGIC;
           rs232_rd : out  STD_LOGIC);
end periph2pc;

architecture Behavioral of periph2pc is
	signal buffpos : integer;
	
	type PERIPHSTATE is (BUFFERING, STARTING, SENDING, STOPPING);
	signal CurrState : PERIPHSTATE;
	
begin
	process(clk_uart, reset)
	begin
		if reset = '1' then
			CurrState <= BUFFERING;
			rs232_rd <= '1';	--This is inverted by the CMOS circuitry, so in reality this signal is 0V
		elsif rising_edge(clk_uart) then
			case CurrState is
				when BUFFERING =>	--Start transmitting when buffok is high and the peripheral is connected to the PC
					clrbuff <= '0';
					if buffok = '1' then --and rs232_dtr = '1' then
						CurrState <= STARTING;
					end if;
					
				when STARTING =>	--Set rd low (i.e. 5V) and reset the buffpos counter to start with the LSB
					rs232_rd <= '0';
					buffpos <= 0;
					CurrState <= SENDING;
					
				when SENDING =>	--Send out the bit pointed by buffpos
					rs232_rd <= buff(buffpos);
					
					--If we've just sent out the MSB, send a stop signal
					if buffpos = buff'length-1 then
						CurrState <= STOPPING;
						
					--Otherwise, increment the buffpos pointer
					else
						buffpos <= buffpos + 1;
					end if;
					
				when STOPPING =>	--Send the stop signal, which is high (i.e. 0V), then clear the buffok flag
					rs232_rd <= '1';
					clrbuff <= '1';
					CurrState <= BUFFERING;
			end case;
		end if;
	end process;
end Behavioral;

