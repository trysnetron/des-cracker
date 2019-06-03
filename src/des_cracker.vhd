------------------------------------------------
-----------------DES cracker--------------------
---by Trym Sneltvedt and Yohann Jacob Sandvik---
------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Setting up entity of the des_cracker --  
entity des_cracker is
port(
    aclk           : in  std_ulogic;                     -- master clock
    aresetn        : in  std_ulogic;                     -- synchronous active low reset

    -- Read address channel signals
    s0_axi_araddr  : in  std_ulogic_vector(11 downto 0); -- read address
    s0_axi_arvalid : in  std_ulogic;                     -- read address valid
    s0_axi_arready : out std_ulogic;                     -- read address acknowledge
	-- arprot

    -- Write address channel signals
    s0_axi_awaddr  : in  std_ulogic_vector(11 downto 0); -- write address
    s0_axi_awvalid : in  std_ulogic;                     -- write address valid flag
    s0_axi_awready : out std_ulogic;                     -- write address acknowledge
	-- awprot

    -- Write data channel signals
    s0_axi_wdata   : in  std_ulogic_vector(31 downto 0); -- write data
    s0_axi_wstrb   : in  std_ulogic_vector(3 downto 0);  -- write byte enables
    s0_axi_wvalid  : in  std_ulogic;                     -- write data and byte enables valid
    s0_axi_wready  : out std_ulogic;                     -- write data and byte enables acknowledge

    -- Read data channel signals
    s0_axi_rdata   : out std_ulogic_vector(31 downto 0); -- read data response to CPU
    s0_axi_rresp   : out std_ulogic_vector(1 downto 0);  -- read status response (OKAY, EXOKAY, SLVERR or DECERR)
    s0_axi_rvalid  : out std_ulogic;                     -- read data and status response valid flag
    s0_axi_rready  : in  std_ulogic;                     -- read response acknowledge

    -- Write response channel signals
    s0_axi_bresp   : out std_ulogic_vector(1 downto 0);  -- write status response (OKAY, EXOKAY, SLVERR or DECERR)
    s0_axi_bvalid  : out std_ulogic;                     -- write status response valid
    s0_axi_bready  : in  std_ulogic;                     -- write response acknowledge

    irq            : out std_ulogic;                     -- interrupt request
    led            : out std_ulogic_vector(3 downto 0)   -- wired to the four user LEDs 
);
end entity des_cracker;

-- Setting up architecture of the des_cracker
architecture rtl of des_cracker is

    signal p   : std_ulogic_vector(63 downto 0); -- The plaintext           base adress: 0x000
    signal c   : std_ulogic_vector(63 downto 0); -- The ciphertext          base adress: 0x008
    signal k0  : std_ulogic_vector(55 downto 0); -- The starting secret key base adress: 0x010
    signal k   : std_ulogic_vector(55 downto 0); -- The current secret key  base adress: 0x018
    signal k1  : std_ulogic_vector(56 downto 0); -- The found secret key    base adress: 0x020

    constant axi_resp_okay		: std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_exokay	: std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_slverr	: std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_decerr	: std_ulogic_vector(1 downto 0) := "11";

	signal crack_begin  : std_ulogic; -- Command to make engines begin checking keys
	signal crack_end	: std_ulogic; -- Command to make engines stop
	signal crack_compl  : std_ulogic; -- Flag for engines let us know that correct key has been found

	type rw_states is (idle, waiting);
    signal state_r, state_w : rw_states;

begin 

    sm: entity work.des_sm(rtl)
    port map(
        clk         => aclk,    
        sresetn     => aresetn,
        crck_begin  => crack_begin,
        plain_txt   => p,
        cipher_txt  => c,
        start_key   => k0,
        found_key   => k1,
        sm_complete => crack_compl
    );

-- Read process.
process(aclk) begin
	if rising_edge(aclk) then
		if aresetn = '0' then
			s0_axi_arready		<= '0';
			s0_axi_rdata 		<= (others => '0');
			s0_axi_rresp 		<= (others => '0');
			s0_axi_rvalid_local	<= '0';

		elsif

		else

		end if;
	end if;
end process;

-- Write process
process(aclk) begin
	if rising_edge(aclk) then
		if aresetn = '0' then
		-- Write address.
			s0_axi_awready_local<= '0';
			s0_axi_wready		<= '0';
			s0_axi_bresp 		<= (others => '0');
			s0_axi_bvalid_local	<= '0';

			p	<= (others => '0');
			c	<= (others => '0');
			k0	<= (others => '0');
			crack_begin <= '0';
		elsif then

		else

		end if;
	end if;
end process;


end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
