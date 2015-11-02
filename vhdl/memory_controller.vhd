------------------------------------------------------------------------
-- Memory controller - an "API" for whatever RAM chip we will go with
-- Use this to read/write 4 bits at a time
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity memory_controller is
    Port ( --Intra-component signals
	        clk : in  STD_LOGIC;
           address : in  STD_LOGIC_VECTOR (10 downto 0);
           write1_read0 : in  STD_LOGIC;
           datain : in  STD_LOGIC_VECTOR (7 downto 0);
			  dataout : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  --External memory chip connections
			  ram_addr : out std_logic_vector (14 downto 0);
			  ram_w1r0 : out std_logic;
			  ram_data : inout std_logic_vector (7 downto 0)
    );
end memory_controller;

architecture Behavioral of memory_controller is
	signal buff : std_logic_vector (7 downto 0);
begin
	process(clk)
	begin
		ram_addr <= "0000" & address;
		ram_w1r0 <= write1_read0;
		if write1_read0 = '1' then
			buff <= datain;
			ram_data <= buff;
		else
			buff <= ram_data;
			dataout <= buff;
		end if;
	end process;
	
end Behavioral;

