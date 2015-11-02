--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:23:53 10/28/2015
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
    PORT(
         clk : IN  std_logic;
         ether_clk : IN  std_logic;
         reset : IN  std_logic;
         ethernet : IN  std_logic;
         read_ok : IN  std_logic;
         ready : OUT  std_logic;
         data : OUT  std_logic_vector(3 downto 0);
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
   signal ethernet : std_logic := '0';
   signal read_ok : std_logic := '0';
	
	signal very_fast_clk : std_logic := '0';
	
	--Passthroughs
	signal rx_to_ram : std_logic_vector (7 downto 0);
	signal ram_to_rx : std_logic_vector (7 downto 0);

 	--Outputs
   signal ready : std_logic;
   signal data : std_logic_vector(3 downto 0);
   signal ram_addr : std_logic_vector(10 downto 0);
   signal ram_w1r0 : std_logic;

   -- Clock period definitions
   constant clk_period : time := 200 ns;
   constant ether_clk_period : time := 50 ns;
	constant very_fast_clk_period : time := 1 ns;
	constant read_period : time := 357 ns;
	
	signal prev_bits : std_logic_vector(3 downto 0) := "0000";
	constant MSB_STOP : std_logic_vector(3 downto 0) := "1110";
	constant LSB_STOP : std_logic_vector(3 downto 0) := "0000";
	signal done : std_logic := '0';
	
	--                                  SYNC                                                                 PAYLOAD                                                                                              CRC32
	constant TEST : std_logic_vector := "1010101010101010101010101010101010101010101010101010101010101011" & "101010011010011010100101100110101001100110010110100101010110101001101001011001100110010101011010" & "0110011001101010011010010101011010101001101010101001011001101001";

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: receiver PORT MAP (
          clk => clk,
          ether_clk => ether_clk,
          reset => reset,
          ethernet => ethernet,
          read_ok => read_ok,
          ready => ready,
          data => data,
          ram_addr => ram_addr,
          ram_w1r0 => ram_w1r0,
          ram_data_in => ram_to_rx,
			 ram_data_out => rx_to_ram
        );

	testram: sync_ram port map (
		clock => very_fast_clk,
		we => ram_w1r0,
		address => "0000" & ram_addr,
		datain => rx_to_ram,
		dataout => ram_to_rx
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
 
   very_fast_clk_process : process
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
		for I in TEST'range loop
			wait for ether_clk_period;
			ethernet <= TEST(I);
		end loop;
		
		wait for ether_clk_period;
		ethernet <= '0';
		wait for ether_clk_period*2.25;
		wait for 37.5ns;
		
		L1: loop
			read_ok <= '1';
			wait for clk_period*4;
			
			if prev_bits = LSB_STOP and data = MSB_STOP then
				exit L1;
			else
				prev_bits <= data;
			end if;
			
			read_ok <= '0';
			wait for clk_period*2;
		end loop;
		
		done <= '1';
      wait;
   end process;

END;
