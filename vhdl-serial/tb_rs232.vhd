--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:45:14 03/06/2016
-- Design Name:   
-- Module Name:   C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/test232/tb_rs232.vhd
-- Project Name:  test232
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: rs232
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
 
ENTITY tb_rs232 IS
END tb_rs232;
 
ARCHITECTURE behavior OF tb_rs232 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
	component ram_sp_ar_aw is
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
 
    COMPONENT rs232
    PORT(
         clk32mhz : IN  std_logic;
         reset : IN  std_logic;
         td : IN  std_logic;
         rd : OUT  std_logic;
         clk_cpu : IN  std_logic;
         cpu_read : IN  std_logic;
         cpu_write : IN  std_logic;
         cpu_cs : IN  std_logic;
         cpu_parity : IN  std_logic;
         cpu_data : INOUT  std_logic_vector(3 downto 0);
         cpu_ready : OUT  std_logic;
         ram_data : INOUT  std_logic_vector(7 downto 0);
         ram_addr : OUT  std_logic_vector(14 downto 0);
         ram_r1w0 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal td : std_logic := '0';
   signal clk_cpu : std_logic := '0';
   signal cpu_read : std_logic := '0';
   signal cpu_write : std_logic := '0';
   signal cpu_cs : std_logic := '0';
   signal cpu_parity : std_logic := '0';

	--BiDirs
   signal cpu_data : std_logic_vector(3 downto 0);
   signal ram_data : std_logic_vector(7 downto 0);

 	--Outputs
   signal rd : std_logic;
   signal cpu_ready : std_logic;
   signal ram_addr : std_logic_vector(14 downto 0);
   signal ram_r1w0 : std_logic;

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
   constant clk_cpu_period : time := 31.25 ns;
	constant clk_uart : time := 104.16666666666666666666666 us;
	
	constant TEST : std_logic_vector := "0011001101" & "0101011101" & "0110001101" & "0110101101" & "0100001001";
	constant YAY : std_logic_vector := "0111111001";
	constant MSG : std_logic_vector := "0101" & "1101";
 
BEGIN

	RAM: ram_sp_ar_aw port map (
		address => ram_addr,
		data => ram_data,
		cs => '1',
		we => not ram_r1w0,
		oe => '1'
	);
 
	-- Instantiate the Unit Under Test (UUT)
   uut: rs232 PORT MAP (
          clk32mhz => clk,
          reset => reset,
          td => td,
          rd => rd,
          clk_cpu => clk_cpu,
          cpu_read => cpu_read,
          cpu_write => cpu_write,
          cpu_cs => cpu_cs,
          cpu_parity => cpu_parity,
          cpu_data => cpu_data,
          cpu_ready => cpu_ready,
          ram_data => ram_data,
          ram_addr => ram_addr,
          ram_r1w0 => ram_r1w0
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clk_cpu_process :process
   begin
		clk_cpu <= '0';
		wait for clk_cpu_period/2;
		clk_cpu <= '1';
		wait for clk_cpu_period/2;
   end process;

cpu_parity <= '0';

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		td <= '1';
		cpu_read <= '0';
		cpu_write <= '0';
		cpu_data <= (others => 'Z');
		
      wait for 100 ns;	
		reset <= '1';
      wait for clk_period*10;
		reset <= '0';
		wait for clk_uart/2;
      -- insert stimulus here 
		for i in TEST'range loop
			wait for clk_uart;
			td <= TEST(i);
		end loop;
		
		wait for 1 ms;
		for i in YAY'range loop
			td <= YAY(i);
			wait for clk_uart;
		end loop;
		
		for i in 0 to 9 loop
			wait for 1 ms;
			cpu_read <= '1';
			wait for clk_cpu_period * 4;
			cpu_read <= '0';
		end loop;
		
		for i in 0 to 1 loop
			wait for 1 ms;
			cpu_write <= '1';
			wait until rising_edge(cpu_ready);
			cpu_data <= MSG(i*4 to i*4+3);
			wait for 1ms;
			cpu_write <= '0';
			cpu_data <= (others => 'Z');
		end loop;
		
      wait;
   end process;

END;
