----------------------------------------------------------------------------------
-- ETHERNET RECEIVER MODULE - Receives data from the ethernet and passes it to the CPU
--
-- Description:	Ethernet receiver. Does not parse received frame in any way.
--						(CONSIDER: check that the received MAC matches our MAC or broadcast)
--
-- Inputs:	clk: master clock from the CPU
--				ether_clk: 20MHz clock ***EXACTLY***
--				reset: resets internal signals
--				read_ok: flag if the CPU can read from the peripheral
--				ethernet: data coming in from the ethernet wire
--
-- Outputs:	ready: the peripheral is ready to write to the CPU
--				data[3:0]: output data from the peripheral to the CPU
--				
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

entity receiver is
    Port ( --Intra-component signals
	        clk : in  STD_LOGIC;
           ether_clk : in STD_LOGIC;
           reset : in  STD_LOGIC;
           ethernet : in  STD_LOGIC;
			  read_ok : in STD_LOGIC;
			  ready : out STD_LOGIC;
			  etherrx_request : out STD_LOGIC;
           data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  --External memory connections
			  ram_addr : out std_logic_vector (10 downto 0);
			  ram_w1r0 : out std_logic;
			  ram_cs : out std_logic;
			  ram_data_in : in std_logic_vector (7 downto 0);
			  ram_data_out : out std_logic_vector (7 downto 0)
     );
end receiver;

architecture Behavioral of receiver is
	component crc
		Port (	clk : in  STD_LOGIC;
					reset : in STD_LOGIC;
					frame_bit : in  STD_LOGIC;
					crc32_out : out  STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;
	signal crc32_clk : std_logic;
	signal crc32_reset : std_logic;
	signal crc32_out : std_logic_vector (31 downto 0);
	
	--Memory controller stuff
	signal mem_addr : unsigned (10 downto 0);
	signal mem_w1r0 : std_logic;
	signal mem_max : unsigned (10 downto 0);
	signal mem_pos : unsigned (2 downto 0);
	
	constant STOP_SIGNAL : std_logic_vector(7 downto 0) := "11100000";
	
	type RXSTATE is (IDLE, SYNC, IGNORE, FRAMERX, RAMSTOP, VALIDATION, CANTTXLSB, DATATXLSB, CANTTXMSB, DATATXMSB);
	signal CurrState : RXSTATE;
		
	signal manual_reset : std_logic;
	signal my_clk : std_logic;
	signal ether_reference : std_logic;
begin
	--Map the CRC component
	FCS : crc port map (
		clk => crc32_clk,
		reset => crc32_reset,
		frame_bit => ethernet,
		crc32_out => crc32_out
	);
	
	--Map internal flags 'cause VHDL really needs these
	ram_addr <= std_logic_vector(mem_addr);
	ram_w1r0 <= mem_w1r0;
	
	--Set the clock to be ether_clk when writing to memory, or clk when reading
	my_clk <= (ether_clk and mem_w1r0) or (clk and not mem_w1r0);
	
	--crc32 reset depends on the external reset and manual reset
	crc32_reset <= reset or manual_reset;
	
	process(my_clk, reset, manual_reset)
	begin
		--Reset the signals to their defaults
		if reset = '1' or manual_reset = '1' then
			CurrState <= IDLE;
			etherrx_request <= '0';
			data <= "ZZZZ";
			ready <= 'Z';
			manual_reset <= '0';
			
			crc32_clk <= '0';
			
			mem_addr <= to_unsigned(2**mem_addr'length-1, mem_addr'length);
			mem_pos <= to_unsigned(0, mem_pos'length);	--Remember, we'll be receiving LSB first, so fill buffer LSB to MSB
			mem_w1r0 <= '1';
			ram_cs <= '1';
								
		--Ethernet functions
		elsif rising_edge(my_clk) then
			--Act based on state
			case CurrState is
				when IDLE =>	--idle state - listen for signals
					--If the received signal is no longer '0', we've received a signal
					--Go to the sync state and set the ethernet reference bit to '1'
					if ethernet = '1' then
						CurrState <= SYNC;
						ether_reference <= '1';
					end if;
					
				when SYNC =>	--synchronization state
					--When the current bit is equal to the previous bit, we are (hopefully) out of the sync state
					--Go to the IGNORE state, since the first transition is usually ignored
					if ethernet = ether_reference then
						CurrState <= IGNORE;
					
					--Otherwise, store the received bit as the ethernet reference bit
					else
						ether_reference <= ethernet;
					end if;
				
				when IGNORE =>	--ignore the received transition
					--Keep track of the bit just received for timeout purposes
					ether_reference <= ethernet;
					
					--Turn off the CRC clock
					crc32_clk <= '0';
					
					--Signal the main board that we are (most likely) receiving actual data and not autonegotiation signals
					etherrx_request <= '1';
					
					--If this is the first position in the byte, increment the memory address
					if mem_pos = 0 then
						mem_addr <= mem_addr + 1;
						mem_pos <= to_unsigned(0, mem_pos'length);
					end if;
					
					--Proceed to the next state
					CurrState <= FRAMERX;
					
				when FRAMERX =>	--receive all the whole frame, including source/destination MAC, size/type, data, and CRC
					--If the received signal is exactly the same as the reference, there have been no transition, i.e. timeout
					--Go to the validation state to check if the frame we received is good
					--Furthermore, write the stop sequence
					if ethernet = ether_reference then
						--Go to the pre-validation stage
						CurrState <= RAMSTOP;
						
						--Set the memory to current - CRC size (4)
						mem_addr <= mem_addr - 4;
						
						--Write the stop signal to the current address
						ram_data_out <= STOP_SIGNAL;
						
					--Otherwise, we consider the arrived bit as a valid data bit
					else
						--Dump the received bit to the CRC circuit
						--Bit is automatically routed to the CRC circuit input, so just trigger the CRC clock
						crc32_clk <= '1';
						
						--Dump the received bit to the memory buffer and increment the memory index
						ram_data_out(to_integer(mem_pos)) <= ethernet;
						
						--Increment the memory position
						mem_pos <= mem_pos + 1;
						
						--Go back to the ignore state
						CurrState <= IGNORE;
					end if;
					
				when RAMSTOP =>	--stop writing to the RAM
					mem_w1r0 <= '0';
					ram_cs <= '0';
					CurrState <= VALIDATION;
					
					--We're done receiving, so allow autonegotiation pulses to be accepted
					etherrx_request <= '0';
		
				when VALIDATION =>	--Validate the data is correct
					--If the CRC is all zeros and the memory position is at 0, our data is correct
					if crc32_out = "00000000000000000000000000000000" and mem_pos = 0 then
						--Go to the data transmission state
						CurrState <= CANTTXLSB;
						
						--Set the RAM to read
						--mem_w1r0 <= '0';	--done above
						
						--The maximum byte length to the current
						mem_max <= mem_addr + 1;
						
						--Reset the frame length
						mem_addr <= to_unsigned(0, mem_addr'length);
						
						--Enable memory chip
						ram_cs <= '1';
						
					--Otherwise, reset
					else
						manual_reset <= '1';
					end if;
				
				when CANTTXLSB =>	--Waiting to be permitted to transmit the least significant bits
					--Load the data
					--Done automatically
					
					
					
					--If the memory address reached the maximum address, reset
					if mem_max = mem_addr then
						manual_reset <= '1';
					
					--If the read flag goes high, go to the transmission state
					elsif read_ok = '1' then
						CurrState <= DATATXLSB;
					end if;
				
				when DATATXLSB =>	--Transmit least significant bits
					if read_ok = '1' then
						ready <= '1';
						data <= ram_data_in(3 downto 0);
				
					--If reading is complete, prepare the next bits
					else
						ready <= 'Z';
						data <= "ZZZZ";
						CurrState <= CANTTXMSB;
					end if;
				
				when CANTTXMSB =>	--Waiting to be permitted to transmit the most significant bits
					--Load the data
					--Done automatically
					
					--If the read flag goes high, go to the transmission state
					if read_ok = '1' then
						CurrState <= DATATXMSB;
					end if;
				
				when DATATXMSB => --Transmit most significant bits
					if read_ok = '1' then
						ready <= '1';
						data <= ram_data_in(7 downto 4);
					
					--Transfer bits only when we're allowed to write
					else
						--Increment the memory address
						mem_addr <= mem_addr + 1;
						
						ready <= 'Z';
						data <= "ZZZZ";
						CurrState <= CANTTXLSB;
					end if;
					
				when others =>
					--This shouldn't happen
			end case;
		end if;
	end process;

end Behavioral;

