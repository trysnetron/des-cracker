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

    -- Read address signals
    s0_axi_araddr  : in  std_ulogic_vector(11 downto 0); -- read address
    s0_axi_arvalid : in  std_ulogic;                     -- read address valid
    s0_axi_arready : out std_ulogic;                     -- read address acknowledge

    -- Write address signals
    s0_axi_awaddr  : in  std_ulogic_vector(11 downto 0); -- write address
    s0_axi_awvalid : in  std_ulogic;                     -- write address valid flag
    s0_axi_awready : out std_ulogic;                     -- write address acknowledge

    -- Read data signals
    s0_axi_wdata   : in  std_ulogic_vector(31 downto 0); -- write data
    s0_axi_wstrb   : in  std_ulogic_vector(3 downto 0);  -- write byte enables
    s0_axi_wvalid  : in  std_ulogic;                     -- write data and byte enables valid
    s0_axi_wready  : out std_ulogic;                     -- write data and byte enables acknowledge

    -- Write data signals
    s0_axi_rdata   : out std_ulogic_vector(31 downto 0); -- read data response to CPU
    s0_axi_rresp   : out std_ulogic_vector(1 downto 0);  -- read status response (OKAY, EXOKAY, SLVERR or DECERR)
    s0_axi_rvalid  : out std_ulogic;                     -- read data and status response valid flag
    s0_axi_rready  : in  std_ulogic;                     -- read response acknowledge

    -- Write response signals
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
    signal k1  : std_ulogic_vector(55 downto 0); -- The found secret key    base adress: 0x020

    signal crack_begin  : std_ulogic;
	signal crack_end	: std_ulogic; 
    signal crack_compl  : std_ulogic;
    signal k_buf		: w56; -- Last processed key buffer.
    
    -- Local AXI signals.
    signal s0_axi_awready_local	: std_ulogic;
    signal s0_axi_rvalid_local	: std_ulogic;
    signal s0_axi_bvalid_local	: std_ulogic;

begin 

    sm: entity work.des_sm(rtl)
    port map(
        clk         => aclk,    
        sresetn     => sresetn,
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

		elsif s0_axi_arvalid = '1' then
		-- Valid adrress on s0_axi_araddr
			if s0_axi_rvalid_local = '0' then		
			
				s0_axi_arready		<= '1'; -- Ready to receive. To complete handshake.
				s0_axi_rvalid_local <= '1'; -- Valid response on bus.
				-- Check address interval.

				-- p
				if unsigned(s0_axi_araddr) < 4 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Lower bits of p.
					s0_axi_rdata <= p(1 to 32);
				elsif unsigned(s0_axi_araddr) < 8 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Upper bits of p.
					s0_axi_rdata <= p(33 to 64);

				-- c
				elsif unsigned(s0_axi_araddr) < 12 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Lower bits of c.
					s0_axi_rdata <= c(1 to 32);
				elsif unsigned(s0_axi_araddr) < 16 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Upper bits of c.
					s0_axi_rdata <= c(33 to 64);

				-- k0
				elsif unsigned(s0_axi_araddr) < 20 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Lower bits of k0.
					s0_axi_rdata <= k0(1 to 32);
				elsif unsigned(s0_axi_araddr) < 24 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Upper bits of k0.
					s0_axi_rdata <= k0(33 to 56) & "00000000";

				-- k
				elsif unsigned(s0_axi_araddr) < 28 then
					s0_axi_rresp <= b"00"; -- OKAY
					k_buf <= k; -- Freeze k.
					-- Lower bits of k.
					s0_axi_rdata <= k_buf(1 to 32);
				elsif unsigned(s0_axi_araddr) < 32 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Upper bits of k.
					s0_axi_rdata <= k_buf(33 to 56) & "00000000";

				-- k1
				elsif unsigned(s0_axi_araddr) < 36 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Lower bits of k0.
					s0_axi_rdata <= k1(1 to 32);
				elsif unsigned(s0_axi_araddr) < 40 then
					s0_axi_rresp <= b"00"; -- OKAY
					-- Upper bits of k0.
					s0_axi_rdata <= k1(33 to 56) & "00000000";

				-- Invalid address.
				else
					s0_axi_rresp <= b"11"; -- DECERR
					s0_axi_rdata <= (others => '0');
				end if;

			else
				if s0_axi_rready = '1' then
					s0_axi_rvalid_local <= '0';
				end if;
				s0_axi_arready <= '0'; -- End handshake.
				-- End of transmission. (Transmissione ends instantly).
			end if;
		else
			if s0_axi_rready = '1' then
				s0_axi_rvalid_local <= '0';
			end if;
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

		elsif s0_axi_awvalid = '1'  and s0_axi_wvalid = '1' and s0_axi_bvalid_local = '0' then
		-- Valid adrress and data.
			if s0_axi_awready_local = '0' then
				s0_axi_awready_local <= '1'; -- Ready to receive. To complete handshake.
				s0_axi_wready <= '1';
				s0_axi_bvalid_local <= '1'; -- Valid response on bus.
				-- Check address interval.
				-- Check address interval.

				-- p
				if unsigned(s0_axi_awaddr) < 4 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Lower bits of p.
					p(1 to 32) <= s0_axi_wdata;
				elsif unsigned(s0_axi_awaddr) < 8 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Upper bits of p.
					p(33 to 64) <= s0_axi_wdata;

				-- c
				elsif unsigned(s0_axi_awaddr) < 12 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Lower bits of c.
					c(1 to 32) <= s0_axi_wdata;
				elsif unsigned(s0_axi_awaddr) < 16 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Upper bits of c.
					c(33 to 64) <= s0_axi_wdata;

				-- k0
				elsif unsigned(s0_axi_awaddr) < 20 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Lower bits of k0.
					k0(1 to 32) <= s0_axi_wdata;
					crack_end <= '1';
				elsif unsigned(s0_axi_awaddr) < 24 then
					s0_axi_bresp <= b"00"; -- OKAY
					-- Upper bits of k0.
					k0(33 to 56) <= s0_axi_wdata(31 downto 8);
					crack_begin <= '1';
					crack_end	<= '0';

				elsif unsigned(s0_axi_awaddr) < 40 then
					s0_axi_bresp <= b"10"; -- SLVERR
				else
					s0_axi_bresp <= b"11"; -- DECERR
				end if;
			else
				start_crack <= '0';
				stop_crack <= '0';
				s0_axi_awready_local <= '0'; -- End handshake.
				s0_axi_wready <= '0';
				if s0_axi_bready = '1' then
					s0_axi_bvalid_local <= '0';
				end if;
			end if;
		else
			start_crack <= '0';
			stop_crack <= '0';
			s0_axi_awready_local <= '0'; -- End handshake.
			s0_axi_wready <= '0';
			if s0_axi_bready = '1' then
				s0_axi_bvalid_local <= '0';
			end if;
		end if;
	end if;
end process;


end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
