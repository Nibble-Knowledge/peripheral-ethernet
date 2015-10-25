----------------------------------------------------------------------------------
-- ETHERNET RECEIVER MODULE - Receives data from the ethernet and passes it to the CPU
--
-- Description:	Ethernet receiver. Does not parse received frame in any way.
--						(CONSIDER: check that the received MAC matches our MAC or broadcast)
--
-- Inputs:	clk: master clock from the CPU
--				ether_clk: 20MHz clock ***EXACTLY***
--				reset: resets internal signals
--				write_ok: flag if the peripheral can write data to the CPU
--				ethernet: data coming in from the ethernet wire
--
-- Outputs:	data[3:0]: output data from the peripheral to the CPU
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
    --Generic (	TIMER_SIZE : integer );
    Port ( clk : in  STD_LOGIC;
           ether_clk : in STD_LOGIC;
           reset : in  STD_LOGIC;
           ethernet : in  STD_LOGIC;
           data : out  STD_LOGIC_VECTOR (3 downto 0));
end receiver;

architecture Behavioral of receiver is
	component crc
		Port (	clk : in  STD_LOGIC;
					reset : in STD_LOGIC;
					frame_bit : in  STD_LOGIC;
					crc32 : inout  STD_LOGIC_VECTOR (31 downto 0));
	end component;
	signal crc32_clk : std_logic;
	signal crc32 : std_logic_vector (31 downto 0);
	
	type RXSTATE is (IDLE, SYNC, FRAMERX, VALIDATION);
	signal CurrState : RXSTATE;
	constant ZERO_VECTOR : std_logic_vector (TIMER_SIZE-1 downto 0) := (others => '0');	--All zeros vector with size TIMER_SIZE for easier sets and comparisons

	signal sync_time : std_logic_vector (TIMER_SIZE-1 downto 0);
	signal current_time : std_logic_vector (TIMER_SIZE-1 downto 0);
	
	signal bit_arrived : std_logic;
	--signal frame : std_logic_vector (12047 downto 0);	--2 bytes length/type + 1500 bytes MAX data + 4 bytes FCS
	--signal frame_size : std_logic_vector (10 downto 0);	--Represent up to 1506 bytes of frame
	signal bit_counter : std_logic_vector (13 downto 0);
begin
	--Map the CRC component
	FCS : crc port map (
		trigger => crc_trigger,
		reset => reset,
		frame_bit => ethernet,
		crc32 => crc32
	);
	
	--Map the RAM component
	RAM : memory port map (
		Clock => clk,
		Reset => reset,
		DataIn => ethernet,
		Address => bit_counter,
		WriteEn => bit_arrived,
		Enable => '1',
		DataOut => open
	);
	
	process(clk, reset, ethernet)
	begin
		--Reset the signals to their defaults
		if reset = '1' then
			CurrState <= IDLE;
			data <= "0000";
			sync_time <= ZERO_VECTOR;
			current_time <= ZERO_VECTOR;
			crc_trigger <= '0';
			bit_arrived <= '0';
		
		--Ethernet clock filter
		elsif ethernet'event then
			case CurrState is
				when IDLE|SYNC =>	--accept arbitrary signal as is
					bit_arrived <= '1';
				when others =>	--only allow data to pass through when the time elapsed is close to sync_time
					if unsigned(current_time) >= unsigned(sync_time)-1 then
						bit_arrived <= '1';
					end if;
			end case;
	
		--Actual ethernet processor
		elsif clk'event and bit_arrived = '1' then
			--Clear the bit arrival bit
			bit_arrived <= '0';
			
			--Reset the time elapsed
			current_time <= (0 => '1', others => '0');
		
			--Act based on state
			case CurrState is
				when IDLE =>	--idle state - listen for signals
					--Start the synchronization process
					CurrState <= SYNC;
					sync_time <= (0 => '0', others => '1');	--Set to the highest number minus 1
					
				when SYNC =>	--synchronization state
					--If the last received signal took longer to trigger than the one before, we have finished the syncing process
					--Advance to the next state and double the sync time (TODO: explain why, but for now, just trust me)
					if unsigned(current_time) > unsigned(sync_time)+1 then
						CurrState <= FRAMERX;
						sync_time <= sync_time(TIMER_SIZE-2 downto 0) & '0';	--Doubling=shifting left
						--frame_size <= (others => '0');	--Reset the frame size
						bit_counter <= (others => '0');	--Reset the bit counter
						--frame <= (others => '0');	--Reset the frame
					
					--Otherwise, set the elapsed time as the syncing period
					else
						sync_time <= current_time;
					end if;
					
				when FRAMERX =>	--receive all the whole frame, including source/destination MAC, size/type, data, and CRC
					--***IGNORE*** Insert the received bit at the end of the frame, shifting the rest left
					--frame <= frame(12046 downto 0) & ethernet;
					
					--Insert the received bit into the memory at the bit_counter's address
					--Done automatically
					
					--Pass received bit to the checksum module
					crc_trigger <= not crc_trigger;
					
					--Increment the number of bits received
					bit_counter <= std_logic_vector(unsigned(bit_counter) + 1);
					
					--***IGNORE*** If the bit counter overflowed, we have received a whole byte, so increment the frame length
					--if bit_counter = "000" then
					--	frame_size <= std_logic_vector(unsigned(frame_size) + 1);
					--end if;
				
					--Note there is no way to progress to the next state - that's the task of the clock listener
					
				when others =>
					null;	--This should not happen
				end case;
					
		--Once we've received all the data, check that our received data makes sense
		elsif CurrState = VALIDATION then
			--Turn off the current time clock
			sync_time <= ZERO_VECTOR;
			
			--Check that the remainder FCS is equal to zero
			if crc32 = "00000000000000000000000000000000" then
				--TODO: transfer data
				
			--If it doesn't, our packet is bad, so throw it away
			else
				CurrState <= IDLE;
			end if;
		
		--Keep track of the number of clock cycles, assuming we're receiving data
		elsif clk'event and (CurrState = SYNC or sync_time /= ZERO_VECTOR) then
			current_time <= std_logic_vector(unsigned(current_time) + 1);
			
			--Timeout if we reached zero
			if current_time = ZERO_VECTOR then
				--If we were in the DATARX state, assume that we received the entire data packet - go validate the frame
				--Also make sure that the size of our frame is in whole bytes, not a bit too much
				--That happens when the total number of bits received is divisible by 8, i.e. current bit count is at '111'
				if CurrState = FRAMERX and bit_counter(2 downto 0) = "111" then
					CurrState <= VALIDATION;
				--Otherwise, assume general timeout or corruption and listen for the next connection
				else
					CurrState <= IDLE;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

