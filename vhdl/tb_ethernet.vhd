--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:37:36 11/01/2015
-- Design Name:   
-- Module Name:   C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/ethernet/tb_ethernet.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ethernet
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
 
ENTITY tb_ethernet IS
END tb_ethernet;
 
ARCHITECTURE behavior OF tb_ethernet IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ethernet
    PORT(
         clk : IN  std_logic;
         ether_clk : IN  std_logic;
         reset : IN  std_logic;
         read_ok : IN  std_logic;
         write_ok : IN  std_logic;
         enabled : IN  std_logic;
         ethernet_in : IN  std_logic;
         data : INOUT  std_logic_vector(3 downto 0);
         ethernet_out : OUT  std_logic;
         ready : OUT  std_logic;
         ethertx_enable : OUT  std_logic;
         ram1_addr : OUT  std_logic_vector(10 downto 0);
         ram1_r1w0 : OUT  std_logic;
			ram1_cs : OUT  std_logic;
         ram1_data : INOUT  std_logic_vector(7 downto 0);
         ram2_addr : OUT  std_logic_vector(10 downto 0);
         ram2_r1w0 : OUT  std_logic;
			ram2_cs : OUT  std_logic;
         ram2_data : INOUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	 
	 component ram_sp_ar_aw
		 generic (
			  DATA_WIDTH :integer := 8;
			  ADDR_WIDTH :integer := 15
		 );
		 port (
			  address :in    std_logic_vector (ADDR_WIDTH-1 downto 0);  -- address Input
			  data    :inout std_logic_vector (DATA_WIDTH-1 downto 0);  -- data bi-directional
			  cs      :in    std_logic;                                 -- Chip Select
			  we      :in    std_logic;                                 -- Write Enable/Read Enable
			  oe      :in    std_logic                                  -- Output Enable
		 );
	end component;
    

   --Inputs
   signal clk : std_logic := '0';
   signal ether_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal read_ok : std_logic := '0';
   signal write_ok : std_logic := '0';
   signal enabled : std_logic := '0';
   signal ethernet_in : std_logic := '0';

	--BiDirs
   signal data : std_logic_vector(3 downto 0);
   signal ram1_data : std_logic_vector(7 downto 0);
   signal ram2_data : std_logic_vector(7 downto 0);

 	--Outputs
   signal ethernet_out : std_logic;
   signal ready : std_logic;
   signal ethertx_enable : std_logic;
   signal ram1_addr : std_logic_vector(10 downto 0);
   signal ram1_r1w0 : std_logic;
	signal ram1_cs : std_logic;
   signal ram2_addr : std_logic_vector(10 downto 0);
   signal ram2_r1w0 : std_logic;
	signal ram2_cs : std_logic;

   -- Clock period definitions
   constant clk_period : time := 200 ns;
   constant ether_clk_period : time := 50 ns;
	
	signal prev_bits : std_logic_vector(3 downto 0) := "0000";
	constant MSB_STOP : std_logic_vector(3 downto 0) := "1110";
	constant LSB_STOP : std_logic_vector(3 downto 0) := "0000";
	signal done : std_logic := '0';
	
	constant TEST : std_logic_vector (55 downto 0) := "1000" & "0100" & "1100" & "0010" & "1010" & "0110" & "1110" & "0001" & "1001" & "0101" & "1101" & "0011" & LSB_STOP & MSB_STOP;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ethernet PORT MAP (
          clk => clk,
          ether_clk => ether_clk,
          reset => reset,
          read_ok => read_ok,
          write_ok => write_ok,
          enabled => enabled,
          ethernet_in => ethernet_in,
          data => data,
          ethernet_out => ethernet_out,
          ready => ready,
          ethertx_enable => ethertx_enable,
          ram1_addr => ram1_addr,
          ram1_r1w0 => ram1_r1w0,
			 ram1_cs => ram1_cs,
          ram1_data => ram1_data,
          ram2_addr => ram2_addr,
          ram2_r1w0 => ram2_r1w0,
			 ram2_cs => ram2_cs,
          ram2_data => ram2_data
        );
		  
	RAM1: ram_sp_ar_aw PORT MAP (
			address => "0000" & ram1_addr,
			data => ram1_data,
			cs => not ram1_cs,
			we => not ram1_r1w0,
			oe => '1'
		);
		
	RAM2: ram_sp_ar_aw PORT MAP (
			address => "0000" & ram2_addr,
			data => ram2_data,
			cs => not ram2_cs,
			we => not ram2_r1w0,
			oe => '1'
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
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		reset <= '1';
      wait for clk_period*10;
		reset <= '0';
      -- insert stimulus here 
		enabled <= '1';
		wait for 1us;
		for I in TEST'length/4-1 downto 0 loop
			write_ok <= '1';
			wait on ready;
			wait for clk_period;
			data <= TEST((I*4)+3 downto I*4);
			wait on ready;
			wait for clk_period;
			write_ok <= '0';
			wait for 2*clk_period;
		end loop;
		
		data <= "ZZZZ";	--TODO: bruh you're incrementing the sync_count when transmitting the CRC too soon, so you get AIDS
		wait for 13us;
		L1: loop
			read_ok <= '1';
			wait on ready;
			
			if prev_bits = LSB_STOP and data = MSB_STOP then
				read_ok <= '0';
				exit L1;
			else
				prev_bits <= data;
			end if;
			
			read_ok <= '0';
			wait on ready;
			wait for clk_period*2;
		end loop;
		
		done <= '1';
      wait;
   end process;
	
	--Map ethernet back to itself
	ethernet_in <= ethernet_out;

END;
