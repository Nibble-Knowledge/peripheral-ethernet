----------------------------------------------------------------------------------
-- Autonegotiation module
-- Maintains link connection
-- TODO: figure out how to actually set the duplex
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

entity autonegotiation is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  pulse_in : in  STD_LOGIC;
           pulse_out : out  STD_LOGIC;
			  established : out  STD_LOGIC);
end autonegotiation;

architecture Behavioral of autonegotiation is
	--Time elapsed since last burst
	--Should be 16+/-8 ms
	signal burst_wait_tx : unsigned(18 downto 0);	--19 bits for 32MHz, ??? bits for 20MHz
	constant burst_wait_period : unsigned(burst_wait_tx'range) := to_unsigned(512000, burst_wait_tx'length);	--512000 for 32MHz, ??? for 20MHz
	constant BURST_WAIT_MIN : unsigned(burst_wait_tx'range) := to_unsigned(256000, burst_wait_tx'length);	--256000 for 32MHz, ??? for 20MHz
	
	--Time elapsed since last received pulse
	--The absolute maximum time between two clock pulses is 125+14=139us
	signal pulse_wait_rx : unsigned(burst_wait_tx'range);
	constant PULSE_WAIT_MAX : unsigned(pulse_wait_rx'range) := to_unsigned(4448, pulse_wait_rx'length);	--4448 for 32MHz, ??? for 20MHz
	signal reset_pulse_wait_rx : std_logic;	--use in receiver
	signal reset_pulse_wait_ref : std_logic;	--use in transmitter for reference
	signal pulse_wait_rx_reset_request : std_logic;
	
	--Time elapsed since the last pulse has started to be transmitted
	--Should be ~100ns, <200ns
	signal pulse_length_tx : unsigned(2 downto 0);	--4*31.25ns for 32MHz, 2*50ns for 20MHz
	constant pulse_length_period : unsigned(pulse_length_tx'range) := to_unsigned(4, pulse_length_tx'length);
	
	--Time elapsed between data pulses within an FLP
	--Should be 62.5+/-7 us
	--Remember to subtract off the pulse transmission length (which is negligible)
	signal pulse_wait_tx : unsigned(10 downto 0);	--11 bits for 32MHz and 20MHz
	constant pulse_wait_period : unsigned(pulse_wait_tx'range) := to_unsigned(2000, pulse_wait_tx'length);	--2000 for 32MHz, 1250 for 20MHz
	
	--Should we be sending auto-negotiation FLPs (as opposed to standard NLPs)?
	signal send_flp : std_logic;
	
	--Did we detect a cable plugged in?
	--signal established : std_logic;
	
	--Received pulse count
	--Counting to 15 is good enough
	signal pulse_count_rx : unsigned(3 downto 0);
	
	--Autonegotiation constant
	constant ANEG_BURST : std_logic_vector := "111010101010111010101010101011101";
	--                                          | | | | |   |               |
	--                                          +-+-+-+-+---+---------------+--- IEEE802.3
	--                                                      +---------------+--- 10BASE-T full duplex
	--                                                                      +--- Acknowledge bit - goes high whenever it receives 3 identical bursts (excl. acknowledge bit)
	--                                                                           (we're too lazy, so we send this high every time)
	constant NLP_BURST : std_logic_vector :=  "100000000000000000000000000000000";
	signal SELECTED_BITS : std_logic_vector(ANEG_BURST'range);
	signal aneg_bit : unsigned(5 downto 0);	--we have 33 bits to take care of
	
	--Pulse state for transmitting pulses/autonegotiation
	--type PULSESTATE is (IDLE, PULSING, WAITING);
	--signal CurrStateTx : PULSESTATE;
	
	type RXSTATE is (PULSING, WAITING, IDLE);
	signal CurrState : RXSTATE;
	
begin
	SELECTED_BITS <= ANEG_BURST when (send_flp = '1') else NLP_BURST;
	pulse_wait_rx_reset_request <= reset_pulse_wait_rx xor reset_pulse_wait_ref;
	established <= not send_flp;

	process(pulse_in, reset)
	begin
		if reset = '1' then
			send_flp <= '1';
			pulse_count_rx <= to_unsigned(0, pulse_count_rx'length);
			reset_pulse_wait_rx <= '0';
		elsif rising_edge(pulse_in) then
			--Oh, we're here? There must be a link
			--established <= '1';

			--If we are sending NLPs, but a pulse came in before the minimum time elapsed, start auto-negotiating
			if send_flp = '0' and pulse_wait_rx < BURST_WAIT_MIN then
				send_flp <= '1';
			end if;
			
			--If we are sending FLPs, a pulse comes after the maximum time between pulses, but the pulse count was too small, start sending NLPs
			if send_flp = '1' and pulse_wait_rx > PULSE_WAIT_MAX and pulse_count_rx < 15 then
				send_flp <= '0';
			end if;
			
			--If we are receiving a new burst, reset the pulse counter
			if pulse_wait_rx > BURST_WAIT_MIN then
				pulse_count_rx <= to_unsigned(0, pulse_count_rx'length);
			--Otherwise, if the counter hasn't reached its maximum, increment it
			elsif pulse_count_rx < 15 then
				pulse_count_rx <= pulse_count_rx + 1;
			end if;
			
			--Please reset pulse wait here
			--pulse_wait_rx <= to_unsigned(0, pulse_wait_rx'length);
			--Done in the other process
			reset_pulse_wait_rx <= not reset_pulse_wait_rx;
			
		end if;
	end process;

	process(clk, reset)
	begin
		--When a reset occurs
		if reset = '1' then
			CurrState <= PULSING;
			pulse_length_tx <= to_unsigned(0, pulse_length_tx'length);
			aneg_bit <= to_unsigned(0, aneg_bit'length);
			burst_wait_tx <= to_unsigned(0, burst_wait_tx'length);
			pulse_wait_rx <= to_unsigned(0, pulse_wait_rx'length);
			pulse_wait_tx <= to_unsigned(0, pulse_wait_tx'length);
			reset_pulse_wait_ref <= '0';
		
		--Triggered when a new pulse comes in
		--elsif rising_edge(pulse_in) then
			--If a link is established and we are sending NLPs, but a pulse came in before the minimum time elapsed, start auto-negotiating
			--if established = '1' and send_flp = '0' and pulse_wait_rx < BURST_LENGTH_MIN then
			--	send_flp <= '1';
			--end if;
		
			--Reset all the relevant counters
			--pulse_wait_rx <= '0';
			
			
		--Triggered on a fast clock edge
		elsif rising_edge(clk) then
			--For transmitting pulses, act based on state
			case CurrState is
				when PULSING =>	--send pulses
					--If the pulse length counter reached its maximum, stop pulsing
					if pulse_length_tx = PULSE_LENGTH_PERIOD then
						pulse_out <= '0';
						pulse_length_tx <= to_unsigned(0, pulse_length_tx'length);
						
						--If we just finished transmitting the last pulse, idle
						if aneg_bit = 32 then
							aneg_bit <= to_unsigned(0, aneg_bit'length);
							CurrState <= IDLE;
							
						--Otherwise, wait until allowed to send the next pulse
						else
							aneg_bit <= aneg_bit + 1;
							CurrState <= WAITING;
						end if;
						
					--Otherwise, pulse out the selected bit and increment the counter
					else
						pulse_out <= SELECTED_BITS(to_integer(aneg_bit));
						pulse_length_tx <= pulse_length_tx + 1;
					end if;
					
				when WAITING =>	--wait to be allowed to pulse again
					--If the pulse wait counter reached its maximum, start pulsing again
					if pulse_wait_tx = PULSE_WAIT_PERIOD then
						pulse_wait_tx <= to_unsigned(0, pulse_wait_tx'length);
						CurrState <= PULSING;
						
					--Otherwise, keep waiting, increment counter
					else
						pulse_wait_tx <= pulse_wait_tx + 1;
					end if;
					
				when IDLE =>	--If we're here, we're between bursts
					--If the burst wait counter reached its maximum, start sending out bursts again
					if burst_wait_tx = BURST_WAIT_PERIOD then
						burst_wait_tx <= to_unsigned(0, burst_wait_tx'length);
						CurrState <= PULSING;
						
					--Otherwise, keep waiting, incrementing counter
					else
						burst_wait_tx <= burst_wait_tx + 1;
					end if;
			end case;
			
			--Autoincrement or reset some counters for the receiving process
			if pulse_wait_rx_reset_request = '1' then
				pulse_wait_rx <= to_unsigned(0, pulse_wait_rx'length);
				reset_pulse_wait_ref <= not reset_pulse_wait_ref;
			else
				pulse_wait_rx <= pulse_wait_rx + 1;
			end if;
			
		end if;
	end process;

	--Process for receiving pulses
	--ah feck who cares pls kill me
--	process(clk, pulse_in, reset)
--	begin
--		if reset = '1' then
--			pulse_wait_rx <= to_unsigned(0, pulse_wait_rx'length);
--			send_flp <= '1';	--start up by sending autonegotiation bursts
--		else
--			--This gets called when we have received a burst
--			if rising_edge(pulse_in) then
--				--Reset the elapsed time between received bursts
--				pulse_wait_rx <= to_unsigned(0, pulse_wait_rx'length);
--			end if;
--			
--			--This gets called on fast clock rising edge (i.e. 31.25ns for 32MHz, 50ns for 20MHz)
--			if rising_edge(clk) then
--				
--			end if;
--		end if;
--	end process;

	--Process for transmitting pulses
--	process(clk, reset)
--	begin
--		if reset = '1' then
--			pulse_wait_tx <= to_unsigned(0, pulse_wait_tx'length);
--			--pulse_length <= to_unsigned(0, pulse_length'length);
--			CurrStateTx <= IDLE;
--			--pulse_out <= '0';
--			send_flp <= '1';	--remove me!
--		elsif rising_edge(clk) then
--			--If the time elapsed between bursts reached the max, reset it and start transmitting the next burst
--			if pulse_wait_tx = pulse_wait_period then
--				pulse_wait_tx <= to_unsigned(0, pulse_wait_tx'length);
--				pulse_length_tx <= to_unsigned(0, pulse_length_tx'length);
--				aneg_bit <= to_unsigned(0, aneg_bit'length);
--				CurrStateTx <= PULSING;
--			--Otherwise, just increment the counter
--			else
--				pulse_wait_tx <= pulse_wait_tx + 1;
--			end if;
--		
--			case CurrStateTx is
--				when IDLE =>	--idling, no signals being transmitted
--					pulse_out <= '0';
--				
--				when PULSING =>	--send out the relevant pulse
--					--If the counter reached its maximum, stop transmitting
--					if pulse_length_tx = pulse_length_period then
--						pulse_out <= '0';
--						
--						--If we just transmitted the last bit, start idling
--						if aneg_bit = 32 then
--							CurrStateTx <= IDLE;
--							aneg_bit <= to_unsigned(0, aneg_bit'length);
--							
--						--Otherwise, wait to transmit the next pulses
--						else
--							CurrStateTx <= WAITING;
--							data_length_tx <= to_unsigned(0, data_length_tx'length);
--							aneg_bit <= aneg_bit + 1;
--						end if;
--						
--					--Otherwise, increment the counter and keep pulsing the selected bit
--					else
--						if send_flp = '1' then
--							pulse_out <= ANEG_BURST(to_integer(aneg_bit));
--						else
--							pulse_out <= NLP_BURST(to_integer(aneg_bit));
--						end if;
--						pulse_length_tx <= pulse_length_tx + 1;
--					end if;
--				
--				when WAITING =>
--					if data_length_tx = data_length_period then
--						CurrStateTx <= PULSING;
--						pulse_length_tx <= to_unsigned(0, pulse_length_tx'length);
--					else
--						data_length_tx <= data_length_tx + 1;
--						--pulse <= '0';
--					end if;
--			end case;
--		end if;
--	end process;
end Behavioral;

