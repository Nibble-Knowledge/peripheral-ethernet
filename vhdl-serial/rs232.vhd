----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:09:52 02/06/2016 
-- Design Name: 
-- Module Name:    rs232 - Behavioral 
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

entity rs232 is
    Port ( clk32mhz : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  
			  --RS232 connections
           td : in  STD_LOGIC;
			  --dtr : in  STD_LOGIC;
			  --rts : in  STD_LOGIC;
           rd : out  STD_LOGIC;
			  --cts : out  STD_LOGIC;
			  
			  --CPU connections
			  clk_cpu : in  STD_LOGIC;
			  cpu_read : in  STD_LOGIC;
			  cpu_write : in  STD_LOGIC;
			  cpu_cs : in  STD_LOGIC;
			  cpu_parity : in  STD_LOGIC;
			  cpu_data : inout  STD_LOGIC_VECTOR(3 downto 0);
			  cpu_ready : out  STD_LOGIC;
			  
			  --RAM connections
			  ram_data : inout  STD_LOGIC_VECTOR(7 downto 0);
			  ram_addr : out  STD_LOGIC_VECTOR(14 downto 0);
			  ram_r1w0 : out  STD_LOGIC;
			  
			  debug : out std_logic
    );
end rs232;

architecture Behavioral of rs232 is
	component clock_divider is
		 Generic ( TICK : integer := 3333 );
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  clk_uart : out  STD_LOGIC);
	end component;
	signal clk_uart : std_logic;
	signal clock_cpu : std_logic;
	
	component pc2periph is
		Port ( clk_uart : in  STD_LOGIC;	--Clock set to the baud rate
				  reset : in  STD_LOGIC;
				  rs232_td : in  STD_LOGIC;	--Data transmitted from PC
				  --rs232_rts : in  STD_LOGIC;	--Request from PC to transmit data
				  mem_inuse : in  STD_LOGIC;
				  rs232_cts : out  STD_LOGIC;	--Response to PC that the peripheral is ready to accept data
				  ram_addr : out  STD_LOGIC_VECTOR (14 downto 0);
				  ram_data : out  STD_LOGIC_VECTOR (7 downto 0));
	end component;
	signal pcin_cts : std_logic;	--we need this because when CTS is high, RAM is in use by this component
	signal pcin_addr : std_logic_vector(14 downto 0);
	signal pcin_data : std_logic_vector(7 downto 0);
	
	component periph2pc is
		Port ( clk_uart : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  --rs232_dtr : in  STD_LOGIC;
				  buff : in  STD_LOGIC_VECTOR (7 downto 0);
				  buffok : in  STD_LOGIC;
				  clrbuff : out  STD_LOGIC;
				  rs232_rd : out  STD_LOGIC);
	end component;
	signal pcout_buff : std_logic_vector(7 downto 0);
	signal pcout_clrbuff : std_logic;
	
	component periph2cpu is
		Port ( clk_cpu : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  in_meminuse : in  STD_LOGIC;
				  cpu_read : in  STD_LOGIC;
				  curmem : in  STD_LOGIC_VECTOR (14 downto 0);
				  ram_data : in  STD_LOGIC_VECTOR (7 downto 0);
				  cpu_ready : out  STD_LOGIC;
				  out_meminuse : out  STD_LOGIC;
				  cpu_data : out  STD_LOGIC_VECTOR (3 downto 0);
				  ram_addr : out  STD_LOGIC_VECTOR (14 downto 0);
				  
				  debug : out std_logic);
	end component;
	signal cpuout_read : std_logic;
	signal cpuout_data : std_logic_vector(7 downto 0);
	signal cpuout_ready : std_logic := '0';
	signal cpuout_meminuse : std_logic;
	signal cpuout_cpudata : std_logic_vector(3 downto 0);
	signal cpuout_addr : std_logic_vector(14 downto 0);
	
	component cpu2periph is
		 Port ( clk_cpu : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  cpu_write : in  STD_LOGIC;
				  cpu_data : in  STD_LOGIC_VECTOR (3 downto 0);
				  --established : in  STD_LOGIC;
				  buffok : in  STD_LOGIC;
				  setbuff : out  STD_LOGIC;
				  pcbuff : out  STD_LOGIC_VECTOR (7 downto 0);
				  cpu_ready : out  STD_LOGIC;
				  
				  debug : out std_logic);
	end component;
	signal cpuin_write : std_logic;
	signal cpuin_data : std_logic_vector(3 downto 0);
	signal cpuin_setbuff : std_logic;
	signal cpuin_ready : std_logic;
	
	--Simple latch for BUFFOK
	signal buffok : std_logic;
	
begin
	CLKDIV: clock_divider
		generic map (
			TICK => 3333
		)
		port map (
			clk => clk32mhz,
			reset => reset,
			clk_uart => clk_uart
		);
		
	CPUCLK: clock_divider
		generic map (
			TICK => 32
		)
		port map (
			clk => clk32mhz,
			reset => reset,
			clk_uart => clock_cpu
		);
		
	PCIN: component pc2periph
		port map (
			clk_uart => clk_uart,
			reset => reset,
			rs232_td => td,
			--rs232_rts => rts,
			mem_inuse => cpuout_meminuse,
			rs232_cts => pcin_cts,
			ram_addr => pcin_addr,
			ram_data => pcin_data
		);
		
	PCOUT: component periph2pc
		port map (
			clk_uart => clk_uart,
			reset => reset,
			--rs232_dtr => dtr,
			buff => pcout_buff,
			buffok => buffok,
			clrbuff => pcout_clrbuff,
			rs232_rd => rd
		);
	
	CPUOUT: component periph2cpu
		port map (
			clk_cpu => clock_cpu,
			reset => reset,
			in_meminuse => pcin_cts,
			cpu_read => cpuout_read,
			curmem => pcin_addr,
			ram_data => cpuout_data,
			cpu_ready => cpuout_ready,
			out_meminuse => cpuout_meminuse,
			cpu_data => cpuout_cpudata,
			ram_addr => cpuout_addr,
			
			debug => open
		);
	
	CPUIN: component cpu2periph
		port map (
			clk_cpu => clock_cpu,
			reset => reset,
			cpu_write => cpuin_write,
			cpu_data => cpuin_data,
			--established => dtr,
			buffok => buffok,
			setbuff => cpuin_setbuff,
			pcbuff => pcout_buff,
			cpu_ready => cpuin_ready,
			
			debug => debug
		);
	
	--Map RS232 signals
	--cts <= pcin_cts;
	
	--Map CPU signals
	cpuout_read <= cpu_read and not cpu_cs;
	cpuin_write <= cpu_write and not cpu_cs;
	cpu_ready <= cpuout_ready when (cpuout_read = '1') else cpuin_ready when (cpuin_write = '1') else 'Z';
	cpu_data <= cpuout_cpudata when (cpuout_read = '1') else (others => 'Z');
	cpuin_data <= cpu_data when (cpuin_write = '1');
	
	--Map RAM signals
	ram_data <= pcin_data when (pcin_cts = '1') else (others => 'Z') when (cpuout_meminuse = '1' or reset = '1');
	cpuout_data <= ram_data when (cpuout_meminuse = '1');
	ram_addr <= pcin_addr when (pcin_cts = '1') else cpuout_addr when (cpuout_meminuse = '1') else (others => '0') when (reset = '1');
	ram_r1w0 <= not pcin_cts;
	
	--BUFFOK latch
	buffok <= '0' when (pcout_clrbuff = '1' or reset = '1') else '1' when (cpuin_setbuff = '1');

end Behavioral;