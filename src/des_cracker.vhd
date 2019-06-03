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
	signal k_local : std_ulogic_vector(55 downto 0); -- The current secret key 

    constant axi_resp_okay		: std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_exokay	: std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_slverr	: std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_decerr	: std_ulogic_vector(1 downto 0) := "11";

	signal crack_begin  : std_ulogic; -- Command to make engines begin checking keys
	signal crack_end	: std_ulogic; -- Command to make engines stop
	signal crack_compl  : std_ulogic; -- Flag for engines let us know that correct key has been found
	signal k_freeze		: std_ulogic; -- Flag to indicate that CPU is reading current key 'k'

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
		current_key => k_local,
        sm_complete => crack_compl
    );

	k <= k_local when k_freeze = '0';

-- Read process.
process(aclk) begin
	if rising_edge(aclk) then
		if aresetn = '0' then
			s0_axi_arready <= '0';
			s0_axi_rdata   <= (others => '0');
			s0_axi_rresp   <= axi_resp_okay;	
		else
			case state_r is
				when idle =>
					if s0_axi_arvalid = '1' then 
						s0_axi_arready <= '1';
						s0_axi_rvalid  <= '1';
						s0_axi_rresp  <= axi_resp_okay; -- change name of constants to cap. letters?
						if unsigned(s0_axi_araddr) < x"004" then -- LSB's of p (plain text)
							-- Unsure what is MSB and LSB
							s0_axi_rdata <= p(31 downto 0);
						if unsigned(s0_axi_araddr) < x"008" then -- MSB's of p
							s0_axi_rdata <= p(63 downto 32);
						if unsigned(s0_axi_araddr) < x"00c" then -- LSB's of c
							s0_axi_rdata <= c(31 downto 0);
						if unsigned(s0_axi_araddr) < x"010" then -- MSB's of c
							s0_axi_rdata <= c(63 downto 32);
						if unsigned(s0_axi_araddr) < x"014" then -- LSB's of k0
							s0_axi_rdata <= k0(31 downto 0);
						if unsigned(s0_axi_araddr) < x"018" then -- MSB's of k0
							s0_axi_rdata <= k0(63 downto 32);
						if unsigned(s0_axi_araddr) < x"01c" then -- LSB's of k
							s0_axi_rdata <= k(31 downto 0);
							k_freeze <= '1'; -- k needs to be frozen
						if unsigned(s0_axi_araddr) < x"020" then -- MSB's of k
							s0_axi_rdata <= k(63 downto 32);
							k_freeze <= '0'; -- k needs to be unfrozen
						if unsigned(s0_axi_araddr) < x"024" then -- LSB's of k1
							s0_axi_rdata <= k1(31 downto 0);
						if unsigned(s0_axi_araddr) < x"028" then -- MSB's of k1
							s0_axi_rdata <= k1(63 downto 32);
						else
							s0_axi_rvalid <= '0';
							s0_axi_rresp  <= axi_resp_decerr;
						end if;
						state_r <= waiting;
					end if;
				when waiting =>
					if s0_axi_rready = '1' then
						s0_axi_rvalid <= '0'; -- Handshake finished, read data no longer valid
						state_r <= idle;
					end if;
			end case;
		end if;
	end if;
end process;

-- Write process
process(aclk) begin
	if rising_edge(aclk) then
		if aresetn = '0' then
			s0_axi_wready <= '0';
			s0_axi_bresp  <= (others => '0');
			p			  <= (others => '0');
			c			  <= (others => '0');
			k0			  <= (others => '0');
			crack_begin	  <= '0';
		else
			case state_w is
				when idle =>
					if s0_axi_awvalid = '1' and s0_axi_wvalid = '1' then
						s0_axi_awready <= '1';
						s0_axi_wready  <= '1';
						s0_axi_bvalid  <= '1';
						s0_axi_bresp   <= axi_resp_okay;
						if unsigned(s0_axi_awaddr) < x"004" then -- LSB's of p (plain text)
							p(31 downto 0) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"008" then -- MSB's of p
							p(63 downto 32) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"00c" then -- LSB's of c
							c(31 downto 0) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"010" then -- MSB's of c
							c(63 downto 32) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"014" then -- LSB's of k0
							-- stop cracking machine
							crack_end <= '1';
							crack_begin <= '0';
							k0(31 downto 0) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"018" then -- MSB's of k0
							-- start cracking machine
							crack_end <= '0';
							crack_begin <= '1';
							k0(63 downto 32) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"01c" then -- LSB's of k
							k(31 downto 0) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"020" then -- MSB's of k
							k(63 downto 32) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"024" then -- LSB's of k1
							k1(31 downto 0) <= s0_axi_wdata;
						if unsigned(s0_axi_awaddr) < x"028" then -- MSB's of k1
							k1(63 downto 32) <= s0_axi_wdata;
						else
							s0_axi_awready <= '0';
							s0_axi_wready <= '0';
							s0_axi_bresp  <= axi_resp_decerr;
						end if;
						state_w <= waiting;
					end if;
				when waiting =>
					if s0_axi_bready = '1' then
						s0_axi_bvalid <= '0';
						state_w <= idle;
					end if;
			end case;
		end if;
	end if;
end process;


end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
