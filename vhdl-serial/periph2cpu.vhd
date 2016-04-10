----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:56:24 02/27/2016 
-- Design Name: 
-- Module Name:    periph2cpu - Behavioral 
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

entity periph2cpu is
    Port ( clk_cpu : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           in_meminuse : in  STD_LOGIC;
           cpu_read : in  STD_LOGIC;
           curmem : in  STD_LOGIC_VECTOR (14 downto 0);
           ram_data : in  STD_LOGIC_VECTOR (7 downto 0);
           cpu_ready : out  STD_LOGIC;
			  out_meminuse : out  STD_LOGIC;
           cpu_data : out  STD_LOGIC_VECTOR (3 downto 0);
           ram_addr : out  STD_LOGIC_VECTOR (14 downto 0);
			  
			  debug : out std_logic);
end periph2cpu;

architecture Behavioral of periph2cpu is
	signal cpumem : integer;
	signal buff : std_logic_vector(7 downto 0);
	
	type PERIPHSTATE is (NODATA, GETDATA, WAIT2MSB, TXMSB, WAIT2LSB, TXLSB);
	signal CurrState : PERIPHSTATE;
	
	signal debug_internal : std_logic;
	
begin
	process(clk_cpu,reset)
	begin
		if reset = '1' then
			CurrState <= NODATA;
			cpumem <= 0;
			
			cpu_ready <= '0';
			out_meminuse <= '0';
			cpu_data <= (others => '0');
			
			debug_internal <= '0';
		elsif rising_edge(clk_cpu) then
			case CurrState is
				when NODATA =>	--wait until cpumem != curmem and memory is not in use
					debug_internal <= not debug_internal;
					if cpumem /= to_integer(unsigned(curmem)) and in_meminuse = '0' then
						CurrState <= GETDATA;
						out_meminuse <= '1';
					end if;
				
				when GETDATA =>	--data should be waiting in ram_data, so copy it to the buffer
					buff <= ram_data;
					CurrState <= WAIT2MSB;
					cpumem <= cpumem + 1;
					--don't let go of memory just yet so we can have enough time to copy data into buffer
					
				when WAIT2MSB =>	--wait for CPU to request a read
					out_meminuse <= '0';	--we can release memory
					if cpu_read = '1' then
						cpu_ready <= '1';
						cpu_data <= buff(7 downto 4);
						CurrState <= TXMSB;
					end if;
					
				when TXMSB =>	--keep transmitting until cpu_read goes low
					if cpu_read = '0' then
						cpu_ready <= '0';
						cpu_data <= (others => '0');
						CurrState <= WAIT2LSB;
					end if;
				
				when WAIT2LSB =>	--wait for CPU to request a read
					if cpu_read = '1' then
						cpu_ready <= '1';
						cpu_data <= buff(3 downto 0);
						CurrState <= TXLSB;
					end if;
					
				when TXLSB =>	--keep transmitting until cpu_read goes low
					if cpu_read = '0' then
						cpu_ready <= '0';
						cpu_data <= (others => '0');
						CurrState <= NODATA;
					end if;
			end case;
		end if;
	end process;
	
	--Do not write directly to these registers
	ram_addr <= std_logic_vector(to_unsigned(cpumem, ram_addr'length));
	debug <= debug_internal;
end Behavioral;

