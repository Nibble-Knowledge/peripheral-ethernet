----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:38:57 10/16/2015 
-- Design Name: 
-- Module Name:    transmitter - Behavioral 
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

entity transmitter is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  trigger : in STD_LOGIC;
			  data_receiving : in STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (3 downto 0);
           ethernet : out  STD_LOGIC);
end transmitter;

architecture Behavioral of transmitter is
	component crc
		Port (	trigger : in  STD_LOGIC;
					reset : in STD_LOGIC;
					frame_bit : in  STD_LOGIC;
					crc32 : inout  STD_LOGIC_VECTOR (31 downto 0));
	end component;
	signal crc_trigger : std_logic;
	signal crc32 : std_logic_vector (31 downto 0);
	
	component memory
		Generic (
			ADDRESS_WIDTH	: integer := 14
		);
		Port (	Clock 	: in  STD_LOGIC;
					Reset 	: in  STD_LOGIC;
					DataIn 	: in  STD_LOGIC;
					Address	: in  STD_LOGIC_VECTOR (ADDRESS_WIDTH - 1 downto 0);
					WriteEn	: in  STD_LOGIC;
					Enable 	: in  STD_LOGIC;
					DataOut 	: out STD_LOGIC);
	end component;
	
	type TXSTATE is (IDLE, DATARX, SYNCTX, ETHERTX, CRCTX);
	signal CurrState : TXSTATE;
	
	signal tx_count : std_logic_vector(1 downto 0);	--64 MHz clock / 20 MHz transfer rate ~= 3
	signal ether_trigger : std_logic;	--Triggers at a rate of approx 20MHz
	
	--signal frame : std_logic_vector (12047 downto 0);	--2 bytes length/type + 1500 bytes MAX data + 4 bytes FCS
	signal frame_size : std_logic_vector (13 downto 0);	--Represent up to 1506 bytes of frame
	
	signal sync_count : std_logic_vector(5 downto 0);	--63 cycles of sync, exluding the final 1 (i.e. 10101011)
	signal manchester_inverter : std_logic;
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
	
	--Ethernet trigger generator - essentially a crappy clock divider
	--Activate only we're in the transmission states
	process(clk, reset)
	begin
		if reset = '1' then
			tx_count <= "00";
			ether_trigger <= '0';
		else
			case CurrState is
				when SYNCTX|ETHERTX|CRCTX =>
					if tx_count = "10" then
						ether_trigger <= not ether_trigger;
						tx_count <= "00";
					else
						tx_count <= std_logic_vector(unsigned(tx_count) + 1);
					end if;
					
				when others =>
					null;
			end case;
		end if;
	end process;
	
	--Data listener and transmitter
	process(reset, trigger, ether_trigger)
	begin
		if reset = '1' then
			crc_trigger <= '0';
			--frame <= (others => '0');
		else
			case CurrState is
				when IDLE =>
					ethernet <= '0';	--Reset the ethernet bit here
					frame_size <= (others => '0');	--also reset the frame size here
				
					--When we're receiving data, go to the next state
					if data_receiving = '1' then
						CurrState <= DATARX;
					end if;
					
				when DATARX =>
					--Buffer the data when it's triggered
					if trigger'event then
						frame <= frame(12043 downto 0) & data;
						frame_size <= std_logic_vector(unsigned(frame_size) + 1);
					
					--If the data receive flag goes low...
					elsif data_receiving = '0' then
						--If the frame size is a multiple of 8 (i.e. we have whole bytes), go to the next state
						if frame_size(2 downto 0) = "000" then
							CurrState <= SYNCTX;
							sync_count <= (others => '1');	--Set the sync count to 63 bits
							
						--Otherwise, something horrible happened - give up and go to the idle state
						else
							CurrState <= IDLE;
						end if;
					end if;
					
				when SYNCTX =>	--Send out a synchronization signal through the ethernet
					--If this is the 64th bit, send out a '1' and go to the next state
					if sync_count = "00000" then
						ethernet <= '1';
						CurrState <= ETHERTX;
						manchester_inverter <= '1';
					
					--Otherwise, send out the opposite of the current bit and decrement the sync count
					else
						ethernet <= not ethernet;
						sync_count <= std_logic_vector(unsigned(sync_count) - 1);
					end if;
				
				when ETHERTX =>	--Send data through the ethernet
					
			end case;
		end if;
	end process;

end Behavioral;

