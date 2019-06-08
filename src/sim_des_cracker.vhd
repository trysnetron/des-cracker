library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.des_pkg.all;

entity des_cracker_sim is
    port(
        irq:            out std_ulogic;
        led:            out std_ulogic_vector(3 downto 0)
    );
end entity des_cracker_sim;

architecture sim of des_cracker_sim is

    constant period:       time :=  1 ns;

    constant addr_p_lsb : w12 := x"000"; 
    constant addr_p_msb : w12 := x"004";
    constant addr_c_lsb : w12 := x"008";
    constant addr_c_msb : w12 := x"00c";
    constant addr_k0_lsb: w12 := x"010";
    constant addr_k0_msb: w12 := x"014";
    constant addr_k_lsb : w12 := x"018";
    constant addr_k_msb : w12 := x"01c";
    constant addr_k1_ls : w12 := x"020";
    constant addr_k1_msb: w12 := x"024";

    constant axi_resp_OKAY	 : std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_EXOKAY : std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_SLVERR : std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_DECERR : std_ulogic_vector(1 downto 0) := "11";

    constant plain_text : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant crrct_key  : w56 := "00010010011010010101101111001001101101111011011111111000";
    constant wrong_key1 : w56 := "00010010011010010101101111001001101101111011011111101110"; -- 10 less than correct key
    constant wrong_key2 : w56 := "00010010011010010101101111001001101101111011011110010100"; -- 100 less than correct key
    constant cipher_txt : w64 := "1000010111101000000100110101010000001111000010101011010000000101";

    -- AXI Lite signals
    signal axi_aclk    : std_ulogic;        
    signal axi_aresetn : std_ulogic; 
    -- Read address channel signals
    signal axi_araddr  : std_ulogic_vector(11 downto 0); 
    signal axi_arvalid : std_ulogic;                     
    signal axi_arready : std_ulogic;                     
    -- Write address channel signals
    signal axi_awaddr  : std_ulogic_vector(11 downto 0); 
    signal axi_awvalid : std_ulogic;                     
    signal axi_awready : std_ulogic;                     

    signal axi_wdata   : std_ulogic_vector(31 downto 0);
    signal axi_wstrb   : std_ulogic_vector(3 downto 0);
    signal axi_wvalid  : std_ulogic;                  
    signal axi_wready  : std_ulogic;                 
    -- Read data channel signals
    signal axi_rdata   : std_ulogic_vector(31 downto 0); 
    signal axi_rresp   : std_ulogic_vector(1 downto 0);  
    signal axi_rvalid  : std_ulogic;                    
    signal axi_rready  : std_ulogic;                     
    -- Write response channel signals
    signal axi_bresp   : std_ulogic_vector(1 downto 0);  
    signal axi_bvalid  : std_ulogic;                     
    signal axi_bready  : std_ulogic;    

    signal read_address:    w12;
    signal read_data:       w32;
    signal read_resp:   std_ulogic_vector(1 downto 0);

    signal write_address:   w12;
    signal write_data:      w32;
    signal write_resp:  std_ulogic_vector(1 downto 0); 
    
    
begin

    u_des_cracker: entity work.des_cracker(rtl)
    port map(
        aclk           => axi_aclk,
        aresetn        => axi_aresetn,

        s0_axi_araddr  => axi_araddr,
        s0_axi_arvalid => axi_arvalid,
        s0_axi_arready => axi_arready,
    
        s0_axi_awaddr  => axi_awaddr,
        s0_axi_awvalid => axi_awvalid,
        s0_axi_awready => axi_awready,
    
        s0_axi_wdata   => axi_wdata,
        s0_axi_wstrb   => axi_wstrb,
        s0_axi_wvalid  => axi_wvalid,
        s0_axi_wready  => axi_wready,
    
        s0_axi_rdata   => axi_rdata,
        s0_axi_rresp   => axi_rresp,
        s0_axi_rvalid  => axi_rvalid,
        s0_axi_rready  => axi_rready,
    
        s0_axi_bresp   => axi_bresp,
        s0_axi_bvalid  => axi_bvalid,
        s0_axi_bready  => axi_bready,
        
        irq            => irq,
        led            => led
    );

    clock_process: process
    begin
        axi_aclk <= '0';
        wait for period / 2;
        axi_aclk <= '1';
        wait for period / 2;
    end process clock_process;

    --test: process
    --    -- Test 1
    --    constant test1_input1: w32 := x"01234567"; 
    --    constant test1_input2: w32 := x"89adcdef"; 
    --
    --procedure axi_read(
    --    -- Clock
    --    signal aclk:     in  std_ulogic;
    --    -- function input
    --    signal address:  in  std_ulogic_vector(11 downto 0);
    --    -- master --> slave 
    --    signal araddr:   out std_ulogic_vector(11 downto 0);
    --    signal arvalid:  out std_ulogic; 
    --    signal rready:   out std_ulogic;
    --    -- slave --> master
    --    signal arready:  in  std_ulogic;
    --    signal rvalid:   in  std_ulogic;
    --    signal rdata:    in  std_ulogic_vector(31 downto 0);
    --    signal rresp:    in  std_ulogic_vector(1 downto 0);
    --    -- function output
    --    signal data:     out std_ulogic_vector(31 downto 0);
    --    signal response: out std_ulogic_vector(1 downto 0)) is
    --begin
    --    -- set the address we want to read from in   araddr
    --    araddr <= address;
    --    -- set address valid high                   arvalid
    --    arvalid <= '1';
    --    -- wait for acknowledge                     arready
    --    wait until rising_edge(aclk) and arready = '1' and rvalid  = '1';
    --    -- set read response acknowledge high
    --    rready <= '1';
    --    -- fetch data and response
    --    data     <= rdata;
    --    response <= rresp;

    --    wait until rising_edge(aclk);
    --    -- set read-ready-acknowledge low
    --    arvalid <= '0';
    --    rready <= '0';
    --end procedure axi_read;

    ---- AXI Lite "Master writes to slave" implementation
    --procedure axi_write(
    --    -- function input
    --    signal aclk:    in  std_ulogic;
    --    signal address: in  std_ulogic_vector(11 downto 0);
    --    signal data:    in  std_ulogic_vector(31 downto 0);
    --    -- master --> slave
    --    signal awaddr:  out std_ulogic_vector(11 downto 0);
    --    signal awvalid: out std_ulogic;
    --    signal wdata:   out std_ulogic_vector(31 downto 0);
    --    signal wstrb:   out std_ulogic_vector(3 downto 0);
    --    signal wvalid:  out std_ulogic;
    --    signal bready:  out std_ulogic;
    --    -- slave --> master
    --    signal awready: in  std_ulogic; 
    --    signal bresp:   in  std_ulogic_vector(1 downto 0);
    --    signal bvalid:  in  std_ulogic;
    --    signal wready:  in  std_ulogic;
    --    -- function output
    --    signal response:out std_ulogic_vector(1 downto 0)
    --    ) is
    --begin
    --    -- set the procedure axi_write address we want to write to in awaddr
    --    awaddr <= address;
    --    -- set address valid flag awvalid high 
    --    awvalid <= '1';
    --    -- put data in wdata field
    --    wdata <= data;
    --    -- set data valid flad wvalid high
    --    wvalid  <= '1';
    --    -- wait for acknowledge
    --    wait until rising_edge(aclk) and awready = '1' and wready  = '1' and bvalid  <= '1';
    --    -- get response and complete handshake. 
    --    response <= bresp;
    --    bready <= '1';

    --    wait until rising_edge(aclk);
    --    awvalid <= '0';
    --    wvalid  <= '0';

    --end procedure axi_write;


    --begin
    --    -- TEST 1 write to p LSB, and read from p LSB, should be the same
    --    
    --    -- Write to p lsb
    --    write_address <= addr_p_lsb;
    --    write_data    <= test1_input1;
    --   -- assert write_resp = axi_resp_OKAY         report "[ TEST 1 ] p lsb write did not respond with OKAY" severity error;
    --    finish;
    --end process test;
    
    test: process
	--procedure for reading 32 bit data
	procedure axi_read (constant address: in w12) is
	begin
		axi_araddr  <= address;
		axi_arvalid <= '1';
		wait on axi_rvalid;
		read_data   <= axi_rdata;
		axi_rready  <= '1';
		wait until rising_edge(axi_aclk);
		axi_arvalid <= '0';
		axi_rready  <= '0';
	end procedure;
	
	--procedure for writing 32 bits of data
	procedure axi_write (constant address: in w12;
			     signal   data:    in w32) is
	begin
		axi_awaddr  <= address;
		axi_wdata   <= to_write;
                axi_wvalid  <= '1';
                axi_awvalid <= '1';
                wait on axi_wready;

		axi_bready  <= '1';
        	wait until rising_edge(axi_aclk);

		axi_bready  <= '0';
		axi_wvalid  <= '0';
		axi_awvalid <= '0';
	end procedure;

	begin
		axi_aresetn <= '0';
		for i in 1 to 5 loop
			wait until rising_edge(axi_aclk);
		end loop;
		-- resetn <= '1';
		-- --write of c
		-- axi_write(c_lsb_addr, c_lsb);
		-- axi_write(c_msb_addr, c_msb);
		-- --write of p
		-- axi_write(p_lsb_addr, p_lsb);
		-- axi_write(p_msb_addr, p_msb);
		-- --read p to check
		-- axi_read(p_lsb_addr);
		-- --write of k0
		-- axi_write(k0_lsb_addr, k0_lsb);
		-- axi_write(k0_msb_addr, k0_msb);
		-- --check if cracking commences as wanted
		-- for i = 1 to 10 loop
		-- 	wait for rising_edge(clk);
		-- end loop;
		-- --read k and confirm that writing of k stops
		-- axi_read(k_lsb);
		-- k(31 downto 0) <= read_local;
		-- for i = 1 to 10
		-- 	wait for rising_edge(clk);
		-- end loop;
		-- axi_read(k_msb);
		-- k(63 downto 32) <= read_local;
		-- --wait for irq
   		-- wait on irq;
		finish;
	end process test;
end architecture sim;
