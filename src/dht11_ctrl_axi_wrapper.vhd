library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dht11_ctrl_axi_wrapper is
	generic(
		frequency_mhz: positive := 125;
		start_us:      positive := 20000;
		warm_us:       positive := 1000000
	);
	port(
		aclk:           in    std_ulogic;
		aresetn:        in    std_ulogic;

		s0_axi_araddr:  in    std_ulogic_vector(11 downto 0);
		s0_axi_arvalid: in    std_ulogic;
		s0_axi_arready: out   std_ulogic;

		s0_axi_awaddr:  in    std_ulogic_vector(11 downto 0);
		s0_axi_awvalid: in    std_ulogic;
		s0_axi_awready: out   std_ulogic;
	
		s0_axi_wdata:   in    std_ulogic_vector(31 downto 0);
		s0_axi_wstrb:   in    std_ulogic_vector(3 downto 0);
		s0_axi_wvalid:  in    std_ulogic;
		s0_axi_wready:  out   std_ulogic;
		
		s0_axi_rdata:   out   std_ulogic_vector(31 downto 0);
		s0_axi_rresp:   out   std_ulogic_vector(1 downto 0);
		s0_axi_rvalid:  out   std_ulogic;
		s0_axi_rready:  in    std_ulogic;
		
		s0_axi_bresp:   out   std_ulogic_vector(1 downto 0);
		s0_axi_bvalid:  out   std_ulogic;
		s0_axi_bready:  in    std_ulogic;
		
		data:           inout std_logic;
		led:            out   std_ulogic_vector(3 downto 0)
	);
end entity dht11_ctrl_axi_wrapper;

architecture rtl of dht11_ctrl_axi_wrapper is

	constant axi_resp_okay:   std_ulogic_vector(1 downto 0) := "00";
	constant axi_resp_exokay: std_ulogic_vector(1 downto 0) := "01";
	constant axi_resp_slverr: std_ulogic_vector(1 downto 0) := "10";
	constant axi_resp_decerr: std_ulogic_vector(1 downto 0) := "11";

	signal data_in:   std_ulogic;
	signal force0:    std_ulogic;
	signal dso:       std_ulogic;
	signal perr:      std_ulogic;
	signal cerr:      std_ulogic;
	signal rh:        std_ulogic_vector(7 downto 0);
	signal t:         std_ulogic_vector(7 downto 0);
	signal last:      std_ulogic;
	signal rh_last:   std_ulogic_vector(7 downto 0);
	signal t_last:    std_ulogic_vector(7 downto 0);
	signal perr_last: std_ulogic;
	signal cerr_last: std_ulogic;
	signal ok:        std_ulogic;
	signal rh_ok:     std_ulogic_vector(7 downto 0);
	signal t_ok:      std_ulogic_vector(7 downto 0);

	type states is (idle, waiting);
	signal state_r, state_w: states;

begin
	-- Drive LEDS
	led <= ok & last & perr_last & cerr_last;
	-- DHT11 CTRL
	u_dht11_ctrl: entity work.dht11_ctrl(rtl)
	generic map(
		frequency_mhz => frequency_mhz,
		start_us      => start_us,
		warm_us       => warm_us
	)
	port map(
		clk      => aclk,
		sresetn  => aresetn,
		data_in  => data_in,
		force0   => force0,
		dso      => dso,
		perr     => perr,
		cerr     => cerr,
		rh       => rh,
		t        => t
	);
	-- Input/Output buffer
	u_tsb : iobuf
	generic map (
		drive      => 12,
		iostandard => "lvcmos33",
		slew       => "slow")
	port map (
		o  => data_in,
		io => data,
		i  => '0',
		t  => force0
	);
	-- Separate process to update _last and _ok variables
	process(aclk)
	begin
		if rising_edge(aclk) then
			if aresetn = '0' then
				last      <= '0';
				rh_last   <= (others => '0');
				t_last    <= (others => '0');
				perr_last <= '0';
				cerr_last <= '0';
				ok        <= '0';
				rh_ok     <= (others => '0');
				t_ok      <= (others => '0');
			elsif dso = '1' then
                last      <= '1';
                rh_last   <= rh;
                t_last    <= t;
                perr_last <= perr;
                cerr_last <= cerr;
                if perr = '0' and cerr = '0' then
                    ok      <= '1';
                    rh_ok   <= rh;
                    t_ok    <= t;
                end if;
            end if;
        end if;
    end process;
	
	-- AXI WRITE PROCESS ----------------------------------------------------------
	process(aclk)
		variable add: natural range 0 to 2**10 - 1;
	begin
		if rising_edge(aclk) then
			s0_axi_awready <= '0';
			s0_axi_wready  <= '0';
			if aresetn = '0' then
				s0_axi_bresp  <= axi_resp_okay;
				s0_axi_bvalid <= '0';
				state_w       <= idle;
			else
				case state_w is
					when idle =>
						if s0_axi_awvalid = '1' and s0_axi_wvalid = '1' then
							s0_axi_awready <= '1';
							s0_axi_wready  <= '1';
							s0_axi_bvalid  <= '1';
							add := to_integer(unsigned(s0_axi_awaddr(11 downto 2)));
							if add = 0 or add = 1 then
								s0_axi_bresp <= axi_resp_slverr;
							else
								s0_axi_bresp <= axi_resp_decerr;
							end if;
							state_w <= waiting;
						end if;
					when waiting =>
						if s0_axi_bready = '1' then
							s0_axi_bvalid <= '0';
							state_w       <= idle;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	-- AXI READ PROCESS ---------------------------------------------------------
	process(aclk)
		variable add: natural range 0 to 2**10 - 1;
	begin
		if rising_edge(aclk) then
			s0_axi_arready <= '0';
			if aresetn = '0' then
				state_r       <= idle;
				s0_axi_rresp  <= axi_resp_okay;
				s0_axi_rvalid <= '0';
				s0_axi_rdata  <= (others => '0');
			else
				case state_r is
					when idle =>
						if s0_axi_arvalid = '1' then
							s0_axi_arready <= '1';
							s0_axi_rvalid  <= '1';
							add := to_integer(unsigned(s0_axi_araddr(11 downto 2)));
							if add = 0 then
								s0_axi_rdata(31)           <= ok;
								s0_axi_rdata(30 downto 16) <= "000000000000000";
								s0_axi_rdata(15 downto 8)  <= rh_ok;
								s0_axi_rdata(7 downto 0)   <= t_ok;
								s0_axi_rresp               <= axi_resp_okay;
							elsif add = 1 then
								s0_axi_rdata(31)           <= last;
								s0_axi_rdata(30)           <= perr_last;
								s0_axi_rdata(29)           <= cerr_last;
								s0_axi_rdata(28 downto 16) <= "0000000000000";
								s0_axi_rdata(15 downto 8)  <= rh_last;
								s0_axi_rdata(7 downto 0)   <= t_last;
								s0_axi_rresp               <= axi_resp_okay;
							else
								s0_axi_rdata <= (others => '0');
								s0_axi_rresp <= axi_resp_decerr;
							end if;
							state_r <= waiting;
						end if;
					when waiting =>
						if s0_axi_rready = '1' then
							s0_axi_rvalid <= '0';
							state_r       <= idle;
						end if;
				end case;
			end if;
		end if;
	end process;

end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
