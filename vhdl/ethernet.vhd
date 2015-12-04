----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:07:42 10/31/2015 
-- Design Name: 
-- Module Name:    ethernet - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ethernet is
    Port ( clk : in  STD_LOGIC;
           ether_clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           read_ok : in  STD_LOGIC;
           write_ok : in  STD_LOGIC;
           enabled : in  STD_LOGIC;
           ethernet_in : in  STD_LOGIC;
           data : inout  STD_LOGIC_VECTOR (3 downto 0);
           ethernet_out : out  STD_LOGIC;
           ready : out  STD_LOGIC;
           ethertx_enable : out  STD_LOGIC;
           ram1_addr : out  STD_LOGIC_VECTOR (10 downto 0);
           ram1_r1w0 : out  STD_LOGIC;
			  ram1_cs : out  STD_LOGIC;
           ram1_data : inout  STD_LOGIC_VECTOR (7 downto 0);
           ram2_addr : out  STD_LOGIC_VECTOR (10 downto 0);
           ram2_r1w0 : out  STD_LOGIC;
			  ram2_cs : out  STD_LOGIC;
           ram2_data : inout  STD_LOGIC_VECTOR (7 downto 0)
		);
end ethernet;

architecture Behavioral of ethernet is
	component receiver
		 Port ( --Intra-component signals
				  clk : in  STD_LOGIC;
				  ether_clk : in STD_LOGIC;
				  reset : in  STD_LOGIC;
				  ethernet : in  STD_LOGIC;
				  read_ok : in STD_LOGIC;
				  ready : out STD_LOGIC;
				  etherrx_request : out STD_LOGIC;
				  data : out  STD_LOGIC_VECTOR (3 downto 0);
				  
				  --External memory connections
				  ram_addr : out std_logic_vector (10 downto 0);
				  ram_w1r0 : out std_logic;
				  ram_cs : out std_logic;
				  ram_data_in : in std_logic_vector (7 downto 0);
				  ram_data_out : out std_logic_vector (7 downto 0)
		  );
	end component;
	signal rx_read : std_logic;
	signal rx_ready : std_logic;
	signal rx_request : std_logic;
	signal rx_data : std_logic_vector (3 downto 0);
	signal internal1_w1r0 : std_logic;
	signal internal1_cs : std_logic;
	signal ram1_in : std_logic_vector (7 downto 0);
	signal ram1_out : std_logic_vector (7 downto 0);
	
	
	component transmitter
		 Port ( --Intra-component signals
				  clk : in  STD_LOGIC;
				  ether_clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  writing : in  STD_LOGIC;
				  data : in  STD_LOGIC_VECTOR (3 downto 0);
				  ready : out  STD_LOGIC;
				  ethernet : out  STD_LOGIC;
				  ethertx_enable : out  STD_LOGIC;
				  ethertx_request : out  STD_LOGIC;
				  
				  --External memory connections
				  ram_addr : out  STD_LOGIC_VECTOR (10 downto 0);
				  ram_w1r0 : out  STD_LOGIC;
				  ram_cs : out  STD_LOGIC;
				  ram_data_in : in  STD_LOGIC_VECTOR (7 downto 0);
				  ram_data_out: out  STD_LOGIC_VECTOR (7 downto 0));
	end component;
	signal tx_write : std_logic;
	signal tx_ready : std_logic;
	signal tx_data : std_logic_vector (3 downto 0);
	signal tx_ether : std_logic;
	signal tx_enable : std_logic;
	signal tx_request : std_logic;
	signal internal2_w1r0 : std_logic;
	signal internal2_cs : std_logic;
	signal ram2_in : std_logic_vector (7 downto 0);
	signal ram2_out : std_logic_vector (7 downto 0);
	
	component autonegotiation
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  pulse_in : in  STD_LOGIC;
				  pulse_out : out  STD_LOGIC;
				  established : out  STD_LOGIC);
	end component;
	signal pulse_in : std_logic;
	signal pulse_out : std_logic;
	signal established : std_logic;
begin
	RX : receiver port map (
		clk => clk,
		ether_clk => ether_clk,
		reset => reset,
		ethernet => ethernet_in,
		read_ok => rx_read,
		ready => rx_ready,
		etherrx_request => rx_request,
		data => rx_data,
		ram_addr => ram1_addr,
		ram_w1r0 => internal1_w1r0,
		ram_cs => internal1_cs,
		ram_data_in => ram1_in,
		ram_data_out => ram1_out
	);
	
	TX : transmitter port map (
		clk => clk,
		ether_clk => ether_clk,
		reset => reset,
		writing => tx_write,
		data => tx_data,
		ready => tx_ready,
		ethernet => tx_ether,
		ethertx_enable => tx_enable,
		ethertx_request => tx_request,
		ram_addr => ram2_addr,
		ram_w1r0 => internal2_w1r0,
		ram_cs => internal2_cs,
		ram_data_in => ram2_in,
		ram_data_out => ram2_out
	);
	
	LINKPULSE : autonegotiation port map (
		clk => ether_clk,
		reset => reset,
		pulse_in => ethernet_in,
		pulse_out => pulse_out,
		established => established
	);
	
	--Map outputs shared by both peripherals
	--Don't forget to set output to high impedance if not in use
	rx_read <= enabled and read_ok;
	tx_write <= enabled and write_ok and established;	--can't write until connection is established
	
	ready <= rx_ready when (rx_read = '1') else tx_ready when (tx_write = '1') else 'Z';
	data <= rx_data when (rx_read = '1') else (others => 'Z');
	tx_data <= data when (tx_write = '1') else (others => 'Z');
	
	--Allow autonegotiation to be interpreted when the transmitter/receiver aren't using the cable
	ethernet_out <= tx_ether when (tx_request = '1') else pulse_out;
	ethertx_enable <= tx_enable when (tx_request = '1') else pulse_out;
	
	--Map RAM
	ram1_r1w0 <= not internal1_w1r0;
	ram1_cs <= not internal1_cs;
	ram1_in <= ram1_data when (internal1_w1r0 = '0') else (others => 'Z');
	ram1_data <= ram1_out when (internal1_w1r0 = '1') else (others => 'Z');
	ram2_r1w0 <= not internal2_w1r0;
	ram2_cs <= not internal2_cs;
	ram2_in <= ram2_data when (internal2_w1r0 = '0') else (others => 'Z');
	ram2_data <= ram2_out when (internal2_w1r0 = '1') else (others => 'Z');

end Behavioral;

