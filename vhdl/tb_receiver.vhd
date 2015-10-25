--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:54:56 10/15/2015
-- Design Name:   
-- Module Name:   C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/ethernet/tb_receiver.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: receiver
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
 
ENTITY tb_receiver IS
END tb_receiver;
 
ARCHITECTURE behavior OF tb_receiver IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT receiver
    GENERIC ( TIMER_SIZE : integer );
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         ethernet : IN  std_logic;
         data : OUT  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal ethernet : std_logic := '0';

 	--Outputs
   signal data : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
	
	-- Other signals
	--                                                SYNC                                                                 PAYLOAD                                                                                              CRC32
	constant TEST : std_logic_vector(223 downto 0) := "1010101010101010101010101010101010101010101010101010101010101011" & "101010011010011010100101100110101001100110010110100101010110101001101001011001100110010101011010" & "0110011001101010011010010101011010101001101010101001011001101001";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: receiver GENERIC MAP (
	       TIMER_SIZE => 5
	     )
	     PORT MAP (
          clk => clk,
          reset => reset,
          ethernet => ethernet,
          data => data
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		reset <= '1';
      wait for clk_period*10;
		reset <= '0';
      -- insert stimulus here 
		for I in 223 downto 0 loop
			wait for 50ns;
			ethernet <= TEST(I);
		end loop;

      wait;
   end process;

END;
