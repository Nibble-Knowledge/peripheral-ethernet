----------------------------------------------------------------------------------
-- uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh hope that the bus timing isn't too fucked up
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

entity transmitter is
    Port ( --Intra-component signals
	        clk : in  STD_LOGIC;
           ether_clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           writing : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (3 downto 0);
           ready : out  STD_LOGIC;
           ethernet : out  STD_LOGIC;
			  ethertx_enable : out  STD_LOGIC;
			  
			  --External memory connections
           ram_addr : out  STD_LOGIC_VECTOR (10 downto 0);
           ram_w1r0 : out  STD_LOGIC;
			  ram_cs : out  STD_LOGIC;
           ram_data_in : in  STD_LOGIC_VECTOR (7 downto 0);
			  ram_data_out: out  STD_LOGIC_VECTOR (7 downto 0));
end transmitter;

architecture Behavioral of transmitter is
	component crc
		Port (	clk : in  STD_LOGIC;
					reset : in STD_LOGIC;
					frame_bit : in  STD_LOGIC;
					crc32_out : inout  STD_LOGIC_VECTOR (31 downto 0)
		);
	end component;
	signal crc32_clk : std_logic;
	signal crc32_reset : std_logic;
	signal crc32_in : std_logic;
	signal crc32_out : std_logic_vector (31 downto 0);
	
	--Memory stuff
	signal mem_addr : unsigned (10 downto 0);
	signal mem_max : unsigned (10 downto 0);
	signal mem_w1r0 : std_logic;
	signal mem_pos : unsigned (2 downto 0);
	
	constant MSB_STOP : std_logic_vector (3 downto 0) := "1110";
	
	type TXSTATE is (IDLE, WRITINGLSB, READYLSB, DATARXLSB, WRITINGMSB, READYMSB, DATARXMSB, ZEROFLUSH, RAMREADY, FRAMESYNC1, FRAMESYNC0, FRAMESYNCEND, NOTFRAMETX, FRAMETX, NOTFRAMECRC, FRAMECRC, SHUTDOWN);
	signal CurrState : TXSTATE;
		
	signal manual_reset : std_logic;
	signal my_clk : std_logic;
	signal sync_count : unsigned (4 downto 0);
	signal buffer_out : std_logic_vector (31 downto 0);
begin
	--Map the CRC component
	FCS : crc port map (
		clk => crc32_clk,
		reset => crc32_reset,
		frame_bit => crc32_in,
		crc32_out => crc32_out
	);
	
	--Map internal flags 'cause VHDL really needs these
	ram_addr <= std_logic_vector(mem_addr);
	ram_w1r0 <= mem_w1r0;
	
	--Set the clock to be clk when writing or ether_clk when reading
	my_clk <= (clk and mem_w1r0) or (ether_clk and not mem_w1r0);
	
	--crc32 reset depends on the external reset and manual reset
	crc32_reset <= reset or manual_reset;
	
	process(my_clk, reset, manual_reset)
	begin
		--Reset the signals to their defaults
		if reset = '1' or manual_reset = '1' then
			CurrState <= IDLE;
			ready <= 'Z';
			manual_reset <= '0';
			sync_count <= to_unsigned(31, sync_count'length);	--31 '10' + 1 '11' sync signals
			ethernet <= '0';
			ethertx_enable <= '0';
			
			crc32_clk <= '0';
			
			mem_addr <= to_unsigned(2**mem_addr'length-1, mem_addr'length);
			mem_w1r0 <= '1';
			--mem_pos <= to_unsigned(0, mem_pos'length);
			ram_cs <= '1';
		
		--Everything else
		elsif rising_edge(my_clk) then
			case CurrState is
				when IDLE =>	--wait for computer to start transferring data
					--Computer transfer data when write flag goes high
					if writing = '1' then
						CurrState <= WRITINGLSB;
					end if;
					
				when WRITINGLSB =>	--wait for computer to raise write flag
					if writing = '1' then
						ready <= '1';
						CurrState <= READYLSB;
					end if;
					
				when READYLSB =>	--blank state - transition to the next
					--also increment address position
					mem_addr <= mem_addr + 1;
					
					CurrState <= DATARXLSB;
				
				when DATARXLSB =>	--Computer is transfering LSB of data to the peripheral
					--Place the data in the memory and set ready flag low
					ram_data_out(3 downto 0) <= data;
					ready <= 'Z';
					
					--Only when the write flag goes low is when we can transition to the next state
					if writing = '0' then
						CurrState <= WRITINGMSB;
					end if;
					
				when WRITINGMSB =>	--wait for computer to raise write flag
					if writing = '1' then
						ready <= '1';
						CurrState <= READYMSB;
					end if;
					
				when READYMSB =>	--blank state - transition to the next
					CurrState <= DATARXMSB;
					
				when DATARXMSB =>	--Computer is transferring MSB of data to the peripheral
					--If the received data is equal to MSB_STOP, this is a stop symbol
					--Start syncing, set maximum frame size, and reset current frame size
					if data = MSB_STOP then
						CurrState <= ZEROFLUSH;
						mem_max <= mem_addr + 3;	--need to append 4 bytes of zeros - 1
						mem_w1r0 <= '0';	--temporarily disable writing
						mem_addr <= mem_addr - 1;
						ram_cs <= '0';
					
					--Otherwise, place data in memory
					else
						ram_data_out(7 downto 4) <= data;
						
						--Only when the write flag goes low is when we can transition to the previous state
						if writing = '0' then
							CurrState <= WRITINGLSB;
						end if;
					end if;
					
					--Set ready flag low regardless of state
					ready <= 'Z';
					
				when ZEROFLUSH =>	--append 4 bytes of zeros at the end to pass to the CRC
					--When the memory address is equal to the maximum, all data has been written to the memory
					--Disable writing, reset the memory address, and go to the next state
					if mem_addr = mem_max then
						mem_addr <= to_unsigned(0, mem_addr'length);
						mem_pos <= to_unsigned(0, mem_pos'length);
						mem_w1r0 <= '0';
						ram_cs <= '0';
						CurrState <= RAMREADY;
					
					--Otherwise, write zeros to the current address and increment it
					else
						mem_w1r0 <= '1';
						ram_data_out <= "00000000";
						mem_addr <= mem_addr + 1;
						ram_cs <= '1';
					end if;
				
				when RAMREADY =>	--give some time for the RAM to stabilize
					ram_cs <= '1';
					CurrState <= FRAMESYNC1;
				
				when FRAMESYNC1 =>	--Send out a '1' sync signal
					ethernet <= '1';
					
					--Don't forget to enable ethernet transmission
					ethertx_enable <= '1';
					
					--If we reached the last memory position, increment the memory address
					if mem_pos = 7 then
						mem_addr <= mem_addr + 1;
					end if;
					
					--Copy a value from memory to the buffer and CRC controller, LSB first
					buffer_out <= buffer_out(30 downto 0) & ram_data_in(to_integer(mem_pos));
					crc32_in <= ram_data_in(to_integer(mem_pos));
					crc32_clk <= '1';
					mem_pos <= mem_pos + 1;
					
					--If the sync counter expired, go to the last sync state
					if sync_count = 0 then
						CurrState <= FRAMESYNCEND;
						
					--Otherwise, decrement the counter and go to the next sync state
					else
						sync_count <= sync_count - 1;
						CurrState <= FRAMESYNC0;
					end if;
					
				when FRAMESYNC0 =>	--Send out a '0' sync signal
					ethernet <= '0';
					
					--Lower CRC clock
					crc32_clk <= '0';
					
					--Return to the previous state
					CurrState <= FRAMESYNC1;
					
				when FRAMESYNCEND =>	--end of the sync period
					--Send out a final '1' to indicate end of sync
					ethernet <= '1';
					
					--Lower CRC clock
					crc32_clk <= '0';
					
					--Bring in the next value
					--Done automatically!
					
					--Go to the next state
					CurrState <= NOTFRAMETX;
					
				when NOTFRAMETX =>	--send the opposite of the frame
					--Turn CRC clock off
					crc32_clk <= '0';
					
					--Send out the negated MSB from the buffer and go to the next state
					ethernet <= not buffer_out(31);
					CurrState <= FRAMETX;
				
				when FRAMETX =>	--send the bit
					--Send the MSB from the buffer to the ethernet
					ethernet <= buffer_out(31);
					
					--Pass the *current* bit to the CRC module and turn on the clock
					crc32_in <= ram_data_in(to_integer(mem_pos));
					crc32_clk <= '1';
					
					--If the memory position is at 7...
					if mem_pos = 7 then
						--If the memory address reached the maximum address, start transmitting the CRC
						if mem_addr = mem_max then
							sync_count <= to_unsigned(31, sync_count'length);	--use the sync count to count the number of CRC bits - remember! We're going MSB to LSB, so count backwards
							CurrState <= NOTFRAMECRC;
							
						--Otherwise, reset the position and increment the memory address
						else
							mem_pos <= to_unsigned(0, mem_pos'length);
							mem_addr <= mem_addr + 1;
							CurrState <= NOTFRAMETX;
						end if;
						
					--Otherwise, increment the memory position and go to the next bit
					else
						mem_pos <= mem_pos + 1;
						CurrState <= NOTFRAMETX;
					end if;
					
					--Place the new bit at the end of the buffer
					buffer_out <= buffer_out(30 downto 0) & ram_data_in(to_integer(mem_pos));
					
				when NOTFRAMECRC =>	--transmit the negated CRC bit
					ethernet <= not crc32_out(to_integer(sync_count));
					CurrState <= FRAMECRC;
					
				when FRAMECRC =>	--transmit the CRC bit
					ethernet <= crc32_out(to_integer(sync_count));
					
					--If the counter expired, we transmitted everything! "Shut down"
					--REMEMBER! We are transmitting the checksum MSB first.
					if sync_count = 0 then
						CurrState <= SHUTDOWN;
						
					--Otherwise, increment the counter and return to the previous state
					else
						sync_count <= sync_count - 1;
						CurrState <= NOTFRAMECRC;
					end if;
					
				when SHUTDOWN	=> --allow last bit to be transmitted, then reset
					manual_reset <= '1';
					
				when others =>
					--this shouldn't happen
			end case;
		end if;
	end process;

end Behavioral;

