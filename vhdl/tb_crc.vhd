--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:51:19 10/13/2015
-- Design Name:   
-- Module Name:   C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/ethernet/tb_crc.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: crc
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_crc IS
END tb_crc;
 
ARCHITECTURE behavior OF tb_crc IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT crc
    PORT(
         trigger : IN  std_logic;
         reset : IN  std_logic;
         frame_bit : IN  std_logic;
         crc32 : INOUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal trigger : std_logic := '0';
   signal reset : std_logic := '0';
   signal frame_bit : std_logic := '0';

 	--Outputs
   signal crc32 : std_logic_vector(31 downto 0);
	
	constant TEST : std_logic_vector (79 downto 0) := "000100100011010001010110011110001001101010111100" & "00000000000000000000000000000000";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: crc PORT MAP (
          trigger => trigger,
          reset => reset,
          frame_bit => frame_bit,
          crc32 => crc32
        );

-- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		reset <= '1';
      wait for 100 ns;
		reset <= '0';
		
      -- insert stimulus here 
		for I in 79 downto 0 loop
			wait for 50ns;
			frame_bit <= TEST(I);
			wait for 50ns;
			trigger <= not trigger;
		end loop;
		
      wait;
   end process;


END;
