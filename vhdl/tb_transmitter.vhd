--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:10:45 10/29/2015
-- Design Name:   
-- Module Name:   C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/ethernet/tb_transmitter.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: transmitter
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
 
ENTITY tb_transmitter IS
END tb_transmitter;
 
ARCHITECTURE behavior OF tb_transmitter IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT transmitter
    PORT(
         clk : IN  std_logic;
         ether_clk : IN  std_logic;
         reset : IN  std_logic;
         writing : IN  std_logic;
         data : IN  std_logic_vector(3 downto 0);
         ready : OUT  std_logic;
         ethernet : OUT  std_logic;
			ethertx_enable : OUT  std_logic;
         ram_addr : OUT  std_logic_vector(10 downto 0);
         ram_w1r0 : OUT  std_logic;
         ram_data_in : IN  std_logic_vector(7 downto 0);
         ram_data_out : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	 
	 component sync_ram
		port (
			 clock   : in  std_logic;
			 we      : in  std_logic;
			 address : in  std_logic_vector (14 downto 0);
			 datain  : in  std_logic_vector (7 downto 0);
			 dataout : out std_logic_vector (7 downto 0)
		);
    end component;
    

   --Inputs
   signal clk : std_logic := '0';
   signal ether_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal writing : std_logic := '0';
   signal data : std_logic_vector(3 downto 0) := (others => '0');
	
	signal very_fast_clk : std_logic := '0';
	
	--Passthroughs
	signal tx_to_ram : std_logic_vector (7 downto 0);
	signal ram_to_tx : std_logic_vector (7 downto 0);

 	--Outputs
   signal ready : std_logic;
   signal ethernet : std_logic;
	signal ethertx_enable : std_logic;
   signal ram_addr : std_logic_vector(10 downto 0);
   signal ram_w1r0 : std_logic;

   -- Clock period definitions
   constant clk_period : time := 200 ns;
   constant ether_clk_period : time := 50 ns;
	constant very_fast_clk_period : time := 1 ns;
	
	--                                                                                                                                                            STOP SIGNAL
	constant TEST : std_logic_vector (55 downto 0) := "1000" & "0100" & "1100" & "0010" & "1010" & "0110" & "1110" & "0001" & "1001" & "0101" & "1101" & "0011" & "0000" & "1110";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: transmitter PORT MAP (
          clk => clk,
          ether_clk => ether_clk,
          reset => reset,
          writing => writing,
          data => data,
          ready => ready,
          ethernet => ethernet,
			 ethertx_enable => ethertx_enable,
          ram_addr => ram_addr,
          ram_w1r0 => ram_w1r0,
          ram_data_in => ram_to_tx,
          ram_data_out => tx_to_ram
        );
		  
	testram: sync_ram port map (
		clock => very_fast_clk,
		we => ram_w1r0,
		address => "0000" & ram_addr,
		datain => tx_to_ram,
		dataout => ram_to_tx
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   ether_clk_process :process
   begin
		ether_clk <= '0';
		wait for ether_clk_period/2;
		ether_clk <= '1';
		wait for ether_clk_period/2;
   end process;
	
	very_fast_clk_process :process
   begin
		very_fast_clk <= '0';
		wait for very_fast_clk_period/2;
		very_fast_clk <= '1';
		wait for very_fast_clk_period/2;
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
		wait for 1us;
		for I in TEST'length/4-1 downto 0 loop
			writing <= '1';
			wait on ready;
			wait for clk_period;
			data <= TEST((I*4)+3 downto I*4);
			wait on ready;
			wait for clk_period;
			writing <= '0';
			wait for 2*clk_period;
		end loop;

      wait;
   end process;

END;
