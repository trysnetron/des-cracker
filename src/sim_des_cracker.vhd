library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity des_cracker_sim is
    port(
        irq:            out std_ulogic;
        led:            out std_ulogic_vector(3 downto 0)
    );
end entity des_cracker_sim;

architecture sim of des_cracker_sim is

    subtype w12 is std_ulogic_vector(32 downto 0);
    constant period:       time := (1.0e3 * 1 ns) / real(frequency_mhz);

    signal aclk           : std_ulogic;        
    signal aresetn        : std_ulogic; 
    -- Read address channel signals
    signal araddr  : std_ulogic_vector(11 downto 0); 
    signal arvalid : std_ulogic;                     
    signal arready : std_ulogic;                     
    -- Write address channel signals
    signal awaddr  : std_ulogic_vector(11 downto 0); 
    signal awvalid : std_ulogic;                     
    signal awready : std_ulogic;                     
    -- Write data channel signals
    signal wdata   : std_ulogic_vector(31 downto 0); 
    signal wstrb   : std_ulogic_vector(3 downto 0);
    signal wvalid  : std_ulogic;                  
    signal wready  : std_ulogic;                 
    -- Read data channel signals
    signal rdata   : std_ulogic_vector(31 downto 0); 
    signal rresp   : std_ulogic_vector(1 downto 0);  
    signal rvalid  : std_ulogic;                    
    signal rready  : std_ulogic;                     
    -- Write response channel signals
    signal bresp   : std_ulogic_vector(1 downto 0);  
    signal bvalid  : std_ulogic;                     
    signal bready  : std_ulogic;                     

    constant addr_p_lsb : w12 := std_ulogic_vector(to_unsigned(x"004"), 12);  
    constant addr_p_msb : w12 := std_ulogic_vector(to_unsigned(x"008"), 12); 
    constant addr_c_lsb : w12 := std_ulogic_vector(to_unsigned(x"00c"), 12);
    constant addr_c_msb : w12 := std_ulogic_vector(to_unsigned(x"010"), 12);
    constant addr_k0_lsb: w12 := std_ulogic_vector(to_unsigned(x"014"), 12);
    constant addr_k0_msb: w12 := std_ulogic_vector(to_unsigned(x"018"), 12);
    constant addr_k_lsb : w12 := std_ulogic_vector(to_unsigned(x"01c"), 12);
    constant addr_k_msb : w12 := std_ulogic_vector(to_unsigned(x"020"), 12);  
    constant addr_k1_ls : w12 := std_ulogic_vector(to_unsigned(x"024"), 12);
    constant addr_k1_msb: w12 := std_ulogic_vector(to_unsigned(x"028"), 12);

    constant axi_resp_OKAY	: std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_EXOKAY	: std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_SLVERR	: std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_DECERR	: std_ulogic_vector(1 downto 0) := "11";

    procedure axi_read(
        -- function input
        signal aclk:     in  std_ulogic;
        signal address:  in  w12;
        -- master --> slave 
        signal address_v:out std_ulogic;
        signal araddr:   out w12;
        signal rready:   out std_ulogic;
        signal arready:  out std_ulogic; 
        -- slave --> master
        signal rvalid:   in  std_ulogic;
        signal rdata:    in  std_ulogic_vector(31 downto 0);
        signal rresp:    in  std_ulogic_vector(1 downto 0)
        -- function output
        signal data:     out std_ulogic_vector(31 downto 0);
        signal response: out std_ulogic_vector(1 downto 0);
        ) is
    begin
        -- set the address we want to read from in   araddr
        araddr <= address;
        -- set address valid high                   arvalid
        arvalid <= '1';
        -- wait for acknowledge                     arready
        wait until rising_edge(aclk) and arready = '1';
        -- set read response acknowledge high
        rready <= '1';
        -- fetch data and response
        data     <= rdata;
        response <= rresp;
        -- set read-ready-acknowledge low
        rready <= '0';
    end procedure axi_read;

    procedure axi_write(
        -- function input
        signal aclk: in std_ulogic;
        signal address: in natural; 
        signal data: in std_ulogic_vector(31 downto 0);
        -- master --> slave
        signal awaddr: out std_ulogic_vector(11 downto 0);
        signal awvalid: out std_ulogic;
        signal wdata: out std_ulogic_vector(31 downto 0)
        signal wstrb: out std_ulogic_vector(3 downto 0)
        signal wvalid: out std_ulogic;
        signal bready: out  std_ulogic;
        -- slave --> master
        signal awready: in std_ulogic; 
        signal bresp: in std_ulogic_vector(1 downto 0)
        signal bvalid: in std_ulogic;
        -- function output
        signal response: out std_ulogic_vector(1 downto 0);
        signal wready: out std_ulogic;
        ) is
    begin
        -- set the address we want to write to in awaddr
        -- set address valid high
        -- put data in wdata field
        -- set write byte enable
        -- set write data and bye enable
    end procedure axi_write;


begin

    process
    begin
        aclk <= '0';
        wait for period / 2;
        aclk <= '1';
        wait for period / 2;
    end process;

    u_des_cracker: entity work.des_cracker(rtl)
    port map(
        aclk           => aclk,
        aresetn        => aresetn,

        s0_axi_araddr  => s0_axi_araddr,
        s0_axi_arvalid => s0_axi_arvalid,
        s0_axi_arready => s0_axi_arready,
        
        s0_axi_awaddr  => s0_axi_awaddr,
        s0_axi_awvalid => s0_axi_awvalid,
        s0_axi_awready => s0_axi_awready,
        
        s0_axi_wdata   => s0_axi_wdata,
        s0_axi_wstrb   => s0_axi_wstrb,
        s0_axi_wvalid  => s0_axi_wvalid,
        s0_axi_wready  => s0_axi_wready,
        
        s0_axi_rdata   => s0_axi_rdata,
        s0_axi_rresp   => s0_axi_rresp,
        s0_axi_rvalid  => s0_axi_rvalid,
        s0_axi_rready  => s0_axi_rready,
        
        s0_axi_bresp   => s0_axi_bresp,
        s0_axi_bvalid  => s0_axi_bvalid,
        s0_axi_bready  => s0_axi_bready,
        
        irq            => irq,
        led            => led
    );

    process
    begin

        -- Test by writing p, c and k to the DES Cracker, waiting 
        -- and retrieving the result.

        -- p: 0123456789ABCDEF
        -- c: 85E813540F0AB405
        -- k: 12695BC9B7B7F8

        s0_axi_araddr   <= (others => '0');
        s0_axi_arvalid  <= '0';
        s0_axi_rready   <= '0';
        s0_axi_awaddr   <= (others => '0');
        s0_axi_awvalid  <= '0';
        s0_axi_wdata    <= (others => '0');
        s0_axi_wstrb    <= (others => '0');
        s0_axi_wvalid   <= '0';
        s0_axi_bready   <= '0';
        aresetn         <= '1';

        -- Write lower part of c
        wait until rising_edge(aclk);
        s0_axi_awaddr  <= x"008"; -- Probably wrong
        s0_axi_awvalid <= '1';
        s0_axi_wdata   <= x"85E81354";
        s0_axi_wvalid  <= '1';
        wait on s0_axi_wready;
        s0_axi_wvalid <= '0';

        -- Write higher part of c
        wait until rising_edge(aclk);
        s0_axi_awaddr  <= x"008"; -- Probably wrong
        s0_axi_awvalid <= '1';
        s0_axi_wdata   <= x"0F0AB405";
        s0_axi_wvalid  <= '1';
        wait on s0_axi_wready;
        s0_axi_wvalid <= '0';

    end process;

-- TESTS THAT NEED TO BE DONE
    -- Check that SM starts correctly
    -- Check that SM stops correctly
    -- READ
        -- works when given correct address
        -- returns decerr when given wrong address
        -- freezing of k works as it is supposed to
    -- WRITE
        -- works correctly when given correct address
        -- returns slverr when one tries to access addresses that are read-only
        -- returns decerr when given wrong address











    -- Submit random AXI4 lite requests
    --process
    --    variable l:   line;
    --    variable rg: rnd_generator;
    --begin
    --    aresetn        <= '0';
    --    s0_axi_araddr  <= (others => '0');
    --    s0_axi_arvalid <= '0';
    --    s0_axi_rready  <= '0';
    --    s0_axi_awaddr  <= (others => '0');
    --    s0_axi_awvalid <= '0';
    --    s0_axi_wdata   <= (others => '0');
    --    s0_axi_wstrb   <= (others => '0');
    --    s0_axi_wvalid  <= '0';
    --    s0_axi_bready  <= '0';
    --    for i in 1 to 10 loop
    --        wait until rising_edge(aclk);
    --    end loop;
    --    aresetn <= '1';
    --    loop
    --        wait until rising_edge(aclk);
    --        s0_axi_rready <= rg.get_std_ulogic;
    --        s0_axi_bready <= rg.get_std_ulogic;
    --        if s0_axi_arvalid = '0' or s0_axi_arready = '1' then
    --            s0_axi_araddr <= rg.get_std_ulogic_vector(12);
    --            if rg.get_integer(0, 9) /= 9 then
    --                s0_axi_araddr(11 downto 3) <= (others => '0');
    --            end if;
    --            s0_axi_arvalid <= rg.get_std_ulogic;
    --        end if;
    --        if s0_axi_awvalid = '0' or s0_axi_awready = '1' then
    --            s0_axi_awaddr <= rg.get_std_ulogic_vector(12);
    --            if rg.get_integer(0, 9) /= 9 then
    --                s0_axi_awaddr(11 downto 3) <= (others => '0');
    --            end if;
    --            s0_axi_awvalid <= rg.get_std_ulogic;
    --        end if;
    --        if s0_axi_wvalid = '0' or s0_axi_wready = '1' then
    --            s0_axi_wdata  <= rg.get_std_ulogic_vector(32);
    --            s0_axi_wstrb  <= rg.get_std_ulogic_vector(4);
    --            s0_axi_wvalid <= rg.get_std_ulogic;
    --        end if;
    --    end loop;
    --end process;
--
    ---- Termination after nmax acquisitions, check periodicity of acquisitions,
    ---- error if no acquisition in twice the warm-up time plus maximum
    ---- acquisition time
    --process
    --    variable l:     line;
    --    constant nmax:  positive := 100;
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    wait until rising_edge(aclk) and aresetn = '1';
    --    for n in 1 to nmax loop
    --        wait until dso = '1' and rising_edge(aclk) for (acquisition_max + warm_us) * 2 us;
    --        if dso /= '1' then
    --            write(l, string'("NON REGRESSION TEST FAILED - "));
    --            write(l, now);
    --            writeline(output, l);
    --            write(l, string'("  NO ACQUISITION IN "));
    --            write(l, (acquisition_max + warm_us) * 2 us);
    --            writeline(output, l);
    --            finish;
    --        end if;
    --        wait until dso = '0' and rising_edge(aclk);
    --    end loop;
    --    write(l, string'("NON REGRESSION TEST PASSED - "));
    --    write(l, now);
    --    writeline(output, l);
    --    finish;
    --end process;
--
    ---- Compute reference values and check flag. Actual and reference values are
    ---- compared only when check flag is true. Check flag is false until reset
    ---- is asserted low and during 10 us after the DHT11 emulator outputs
    ---- reference values.
    --process
    --begin
    --    check     <= false;
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    check     <= true;
    --    last      <= '0';
    --    last_perr <= '0';
    --    last_cerr <= '0';
    --    last_val  <= (others => '0');
    --    ok        <= '0';
    --    ok_val    <= (others => '0');
    --    loop
    --        wait until rising_edge(aclk) and dso = '1';
    --        check <= false;
    --        wait for 10 us;
    --        wait until rising_edge(aclk);
    --        check     <= true;
    --        last      <= '1';
    --        last_perr <= perr;
    --        last_cerr <= cerr;
    --        last_val  <= val;
    --        if perr = '0' and cerr = '0' then
    --            ok      <= '1';
    --            ok_val  <= val;
    --        end if;
    --        wait until rising_edge(aclk) and dso = '0';
    --    end loop;
    --end process;
--
    --led_ref <= (others => '-') when not check else ok & last & last_perr & last_cerr;
--
    ---- Check unknowns
    --process
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    loop
    --        wait until rising_edge(aclk);
    --        check_unknowns(s0_axi_araddr, "s0_axi_araddr");
    --        check_unknowns(s0_axi_arvalid, "s0_axi_arvalid");
    --        check_unknowns(s0_axi_arready, "s0_axi_arready");
    --        check_unknowns(s0_axi_awaddr, "s0_axi_awaddr");
    --        check_unknowns(s0_axi_awvalid, "s0_axi_awvalid");
    --        check_unknowns(s0_axi_awready, "s0_axi_awready");
    --        check_unknowns(s0_axi_wdata, "s0_axi_wdata");
    --        check_unknowns(s0_axi_wstrb, "s0_axi_wstrb");
    --        check_unknowns(s0_axi_wvalid, "s0_axi_wvalid");
    --        check_unknowns(s0_axi_wready, "s0_axi_wready");
    --        check_unknowns(s0_axi_rdata, "s0_axi_rdata");
    --        check_unknowns(s0_axi_rresp, "s0_axi_rresp");
    --        check_unknowns(s0_axi_rvalid, "s0_axi_rvalid");
    --        check_unknowns(s0_axi_rready, "s0_axi_rready");
    --        check_unknowns(s0_axi_bresp, "s0_axi_bresp");
    --        check_unknowns(s0_axi_bvalid, "s0_axi_bvalid");
    --        check_unknowns(s0_axi_bready, "s0_axi_bready");
    --    end loop;
    --end process;
--
    ---- Reference slave behavior on AXI read channels. Use don't care values for no-check.
    --process
    --    variable add: natural range 0 to 2**10 - 1;
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    s0_axi_arready_ref <= '0';
    --    s0_axi_rvalid_ref  <= '0';
    --    s0_axi_rresp_ref   <= (others => '0');
    --    s0_axi_rdata_ref   <= (others => '0');
    --    wait until rising_edge(aclk) and aresetn = '1';
    --    loop
    --        if s0_axi_arvalid = '0' then
    --            wait until rising_edge(aclk) and s0_axi_arvalid = '1';
    --        end if;
    --        add := to_integer(unsigned(s0_axi_araddr(11 downto 2)));
    --        s0_axi_arready_ref <= '1';
    --        s0_axi_rvalid_ref  <= '1';
    --        s0_axi_rresp_ref   <= axi_resp_okay;
    --        if add = 0 then
    --            if not check then
    --                s0_axi_rdata_ref <= (others => '-');
    --            else
    --                s0_axi_rdata_ref <= ok & "000000000000000" & ok_val(39 downto 32) & ok_val(23 downto 16);
    --            end if;
    --        elsif add = 1 then
    --            if not check then
    --                s0_axi_rdata_ref <= (others => '-');
    --            elsif last_perr = '1' then
    --                s0_axi_rdata_ref <= (31 => last, 30 => last_perr, others => '-');
    --            elsif last_cerr = '1' then
    --                s0_axi_rdata_ref <= (31 => last, 30 => last_perr, 29 => last_cerr, others => '-');
    --            else
    --                s0_axi_rdata_ref <= last & last_perr & last_cerr & "0000000000000" & last_val(39 downto 32) & last_val(23 downto 16);
    --            end if;
    --        else
    --            s0_axi_rresp_ref   <= axi_resp_decerr;
    --            s0_axi_rdata_ref   <= (others => '0');
    --        end if;
    --        wait until rising_edge(aclk);
    --        s0_axi_arready_ref <= '0';
    --        if s0_axi_rready = '0' then
    --            wait until rising_edge(aclk) and s0_axi_rready = '1';
    --        end if;
    --        s0_axi_rvalid_ref <= '0';
    --        wait until rising_edge(aclk);
    --    end loop;
    --end process;
--
    --process
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    loop
    --        wait until rising_edge(aclk);
    --        check_ref(v => s0_axi_arready, r => s0_axi_arready_ref, s => "s0_axi_arready");
    --        check_ref(v => s0_axi_rdata, r => s0_axi_rdata_ref, s => "s0_axi_rdata");
    --        check_ref(v => s0_axi_rresp, r => s0_axi_rresp_ref, s => "s0_axi_rresp");
    --        check_ref(v => s0_axi_rvalid, r => s0_axi_rvalid_ref, s => "s0_axi_rvalid");
    --    end loop;
    --end process;
--
    ---- Reference slave behavior on AXI write channels. Use don't care values for no-check.
    --process
    --    variable add: natural range 0 to 2**10 - 1;
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    s0_axi_awready_ref <= '0';
    --    s0_axi_wready_ref  <= '0';
    --    s0_axi_bvalid_ref  <= '0';
    --    s0_axi_bresp_ref   <= (others => '0');
    --    wait until rising_edge(aclk) and aresetn = '1';
    --    loop
    --        if s0_axi_awvalid = '0' or s0_axi_wvalid = '0' then
    --            wait until rising_edge(aclk) and (s0_axi_awvalid = '1') and (s0_axi_wvalid = '1');
    --        end if;
    --        add := to_integer(unsigned(s0_axi_awaddr(11 downto 2)));
    --        s0_axi_awready_ref <= '1';
    --        s0_axi_wready_ref  <= '1';
    --        s0_axi_bvalid_ref  <= '1';
    --        if add < 2 then
    --            s0_axi_bresp_ref   <= axi_resp_slverr;
    --        else
    --            s0_axi_bresp_ref   <= axi_resp_decerr;
    --        end if;
    --        wait until rising_edge(aclk);
    --        s0_axi_awready_ref <= '0';
    --        s0_axi_wready_ref  <= '0';
    --        if s0_axi_bready = '0' then
    --            wait until rising_edge(aclk) and s0_axi_bready = '1';
    --        end if;
    --        s0_axi_bvalid_ref <= '0';
    --        wait until rising_edge(aclk);
    --    end loop;
    --end process;
--
    --process
    --begin
    --    wait until rising_edge(aclk) and aresetn = '0';
    --    loop
    --        wait until rising_edge(aclk);
    --        check_ref(v => s0_axi_awready, r => s0_axi_awready_ref, s => "s0_axi_awready");
    --        check_ref(v => s0_axi_wready, r => s0_axi_wready_ref, s => "s0_axi_wready");
    --        check_ref(v => s0_axi_bvalid, r => s0_axi_bvalid_ref, s => "s0_axi_bvalid");
    --        check_ref(v => s0_axi_bresp, r => s0_axi_bresp_ref, s => "s0_axi_bresp");
    --    end loop;
    --end process;
--
    --postponed process(led, led_ref)
    --begin
    --    check_ref(v => led, r => led_ref, s => "led");
    --end process;
--
end architecture sim;