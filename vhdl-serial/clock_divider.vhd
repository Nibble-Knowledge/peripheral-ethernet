----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:58:11 02/06/2016 
-- Design Name: 
-- Module Name:    clock_divider - Behavioral 
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

entity clock_divider is
    Generic ( TICK : integer := 3333 );
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           clk_uart : out  STD_LOGIC);
end clock_divider;

architecture Behavioral of clock_divider is
	signal counter : integer;
begin
	process(clk, reset)
	begin
		if reset = '1' then
			counter <= 0;
		elsif rising_edge(clk) then
			if counter = TICK then
				clk_uart <= '1';
				counter <= 0;
			else
				clk_uart <= '0';
				counter <= counter + 1;
			end if;
		end if;
	end process;

end Behavioral;

