----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:14:34 02/22/2016 
-- Design Name: 
-- Module Name:    pc2periph - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pc2periph is
    Port ( clk_uart : in  STD_LOGIC;	--Clock set to the baud rate
           reset : in  STD_LOGIC;
           rs232_td : in  STD_LOGIC;	--Data transmitted from PC
           --rs232_rts : in  STD_LOGIC;	--Request from PC to transmit data
           mem_inuse : in  STD_LOGIC;
           rs232_cts : out  STD_LOGIC;	--Response to PC that the peripheral is ready to accept data
           ram_addr : out  STD_LOGIC_VECTOR (14 downto 0);
           ram_data : out  STD_LOGIC_VECTOR (7 downto 0));
end pc2periph;

architecture Behavioral of pc2periph is
	--signal mem_captured : std_logic;	--Memory is exclusively used by this component and no other
	signal mem_addr : integer;
	signal mem_increment : std_logic;	--We'd like to increment the address in START only when we've read a byte
	
	signal data_buf : std_logic_vector(ram_data'range);
	signal data_buf_pos : integer;
	
	--FSM
	type PERIPHSTATE is (START, LISTEN, STOPANDWRITE);
	signal CurrState : PERIPHSTATE;
	
begin
	process(clk_uart, reset)
	begin
		if reset = '1' then
			CurrState <= START;--WAIT4RTS;
			ram_data <= (others => '0');
			--rs232_cts <= '0'; --mem_captured <= '0';
			mem_addr <= 0;
			mem_increment <= '0';
			data_buf <= (others => '0');
		elsif rising_edge(clk_uart) then
			--if rs232_rts = '1' then
				case CurrState is	--begin FSM
					--when WAIT4RTS =>	--Waiting for PC to send an RTS
						--When it does, ensure that memory is not currently in use
						--If that's the case, await the start signal
					--	if mem_inuse = '0' then --and mem_inuse = '0' then
					--		CurrState <= START;
					--	end if;
				
					when START =>	--await the start signal, i.e. transition from high to low
						--YES, YOU HEARD THAT RIGHT! HIGH TO LOW! Why? Everything is going through a CMOS circuit, so signals get inverted
						--BUT! Since the bits themselves are inverted, the CMOS circuit puts them correctly! Strange, innit?
						--So when transition is detected, go to the listening state and buffer the signals
						if rs232_td = '0' then
							CurrState <= LISTEN;
							data_buf_pos <= ram_data'length - 1;
							rs232_cts <= '1';
						else
							rs232_cts <= '0';
							
						--If RTS is lost, wait for it to come back
						--elsif rs232_rts = '0' then
						--	CurrState <= WAIT4RTS;
						end if;
						
						if mem_increment = '1' then
							mem_addr <= mem_addr + 1;
							mem_increment <= '0';
						end if;
						
					when LISTEN =>	--Receive bits
						--In the event that RTS is lost, decrement the address and wait for RTS to come back
						--if rs232_rts = '0' then
						--	CurrState <= WAIT4RTS;
						--	mem_addr <= mem_addr - 1;
							
						--Otherwise, buffer the incoming data
						--else
							data_buf <= rs232_td & data_buf(data_buf'length-1 downto 1);
							
							--If this is the last bit received, go to the next state
							--Otherwise, decrement the bit counter
							if data_buf_pos = 0 then
								CurrState <= STOPANDWRITE;
							else
								data_buf_pos <= data_buf_pos - 1;
							end if;
						--end if;
						
					when STOPANDWRITE =>	--hope that the signals were not screwed up in any way and write it to RAM
						ram_data <= data_buf;
						CurrState <= START;
						mem_increment <= '1';
						
				end case;
			--else
				--Release control of the memory (and turn off CTS)
			--	mem_captured <= '0';
			--end if;
		end if;
	end process;
	
	--If memory is captured, that means we can signal the PC that we're ready to accept data
	--rs232_cts <= mem_captured;
	
	--Do not write directly to these outputs
	ram_addr <= std_logic_vector(to_unsigned(mem_addr, ram_addr'length));
end Behavioral;

