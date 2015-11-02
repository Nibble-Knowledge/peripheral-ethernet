----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:08:23 10/13/2015 
-- Design Name: 
-- Module Name:    crc - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Computes the CRC of a given stream of bits. Feed it bits to frame_bit and trigger with the trigger pin, which responds to changes in the clock.
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

entity crc is
    Port ( clk : in  STD_LOGIC;
           reset : in STD_LOGIC;
           frame_bit : in  STD_LOGIC;
           crc32_out : out  STD_LOGIC_VECTOR (31 downto 0));
end crc;

architecture Behavioral of crc is
	signal crc32 : std_logic_vector (31 downto 0);
begin
	process(clk, reset)
	begin
		if reset = '1' then
			crc32 <= (others => '0');
		elsif rising_edge(clk) then
			crc32(31) <= crc32(30);
			crc32(30) <= crc32(29);
			crc32(29) <= crc32(28);
			crc32(28) <= crc32(27);
			crc32(27) <= crc32(26);
			crc32(26) <= crc32(25) xor crc32(31);
			crc32(25) <= crc32(24);
			crc32(24) <= crc32(23);
			crc32(23) <= crc32(22) xor crc32(31);
			crc32(22) <= crc32(21) xor crc32(31);
			crc32(21) <= crc32(20);
			crc32(20) <= crc32(19);
			crc32(19) <= crc32(18);
			crc32(18) <= crc32(17);
			crc32(17) <= crc32(16);
			crc32(16) <= crc32(15) xor crc32(31);
			crc32(15) <= crc32(14);
			crc32(14) <= crc32(13);
			crc32(13) <= crc32(12);
			crc32(12) <= crc32(11) xor crc32(31);
			crc32(11) <= crc32(10) xor crc32(31);
			crc32(10) <= crc32(9) xor crc32(31);
			crc32(9) <= crc32(8);
			crc32(8) <= crc32(7) xor crc32(31);
			crc32(7) <= crc32(6) xor crc32(31);
			crc32(6) <= crc32(5);
			crc32(5) <= crc32(4) xor crc32(31);
			crc32(4) <= crc32(3) xor crc32(31);
			crc32(3) <= crc32(2);
			crc32(2) <= crc32(1) xor crc32(31);
			crc32(1) <= crc32(0) xor crc32(31);
			crc32(0) <= frame_bit xor crc32(31);
		end if;
	end process;
	
	crc32_out <= crc32;

end Behavioral;

