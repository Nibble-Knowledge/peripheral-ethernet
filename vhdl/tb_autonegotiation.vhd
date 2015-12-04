--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:04:19 11/04/2015
-- Design Name:   
-- Module Name:   C:/Users/Yakov/SkyDrive/School/University Stuff/ENEL500/ethernet/tb_autonegotiation.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: autonegotiation
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
 
ENTITY tb_autonegotiation IS
END tb_autonegotiation;
 
ARCHITECTURE behavior OF tb_autonegotiation IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT autonegotiation
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         pulse_in : IN  std_logic;
         pulse_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal pulse_in : std_logic := '0';

 	--Outputs
   signal pulse_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
	
	constant MY_BURST : std_logic_vector := "111010101010111010101010101010101";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: autonegotiation PORT MAP (
          clk => clk,
          reset => reset,
          pulse_in => pulse_in,
          pulse_out => pulse_out
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
		wait for 1ms;
		
		for I in 10 downto 0 loop
			for J in MY_BURST'range loop
				pulse_in <= MY_BURST(J);
				wait for 100ns;
				pulse_in <= '0';
				wait for 62.75us;
			end loop;
			wait for 14ms;
		end loop;
		
		loop
			pulse_in <= '1';
			wait for 100ns;
			pulse_in <= '0';
			wait for 16ms;
		end loop;
   end process;

END;
