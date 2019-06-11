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

    constant axi_resp_OKAY	 : std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_EXOKAY : std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_SLVERR : std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_DECERR : std_ulogic_vector(1 downto 0) := "11";
    
    constant period:       time :=  1 ns;

    -- AXI Lite signals
    signal axi_aclk    : std_ulogic;        
    signal axi_aresetn : std_ulogic := '1'; 
    -- Read address channel signals
    signal axi_araddr  : w12; 
    signal axi_arvalid : std_ulogic;                     
    signal axi_arready : std_ulogic;                     
    -- Write address channel signals
    signal axi_awaddr  : w12; 
    signal axi_awvalid : std_ulogic;                     
    signal axi_awready : std_ulogic;                     

    signal axi_wdata   : w32;
    signal axi_wstrb   : std_ulogic_vector(3 downto 0);
    signal axi_wvalid  : std_ulogic;                  
    signal axi_wready  : std_ulogic;                 
    -- Read data channel signals
    signal axi_rdata   : w32; 
    signal axi_rresp   : std_ulogic_vector(1 downto 0);  
    signal axi_rvalid  : std_ulogic;                    
    signal axi_rready  : std_ulogic;                     
    -- Write response channel signals
    signal axi_bresp   : std_ulogic_vector(1 downto 0);  
    signal axi_bvalid  : std_ulogic;                     
    signal axi_bready  : std_ulogic;    

    signal read_addr   : w12 := (others => '0');
    signal read_data   : w32 := (others => '0');
    signal read_resp   : std_ulogic_vector(1 downto 0) := (others => '0');

    signal write_addr  : w12 := (others => '0');
    signal write_data  : w32 := (others => '0');
    signal write_resp  : std_ulogic_vector(1 downto 0) := (others => '0'); 
    
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
    
    test: process
        -- AXI Lite - Master read from slave
        procedure axi_read (constant address: in  w12;
                            signal   data   : out w32) is
        begin
            axi_araddr  <= address;
            axi_arvalid <= '1';
            wait on axi_rvalid;

            data        <= axi_rdata;
            read_resp   <= axi_rresp;
            axi_rready  <= '1';
            wait until rising_edge(axi_aclk);
            
            axi_arvalid <= '0';
            axi_rready  <= '0';
            wait until rising_edge(axi_aclk);
        end procedure;
        
        -- AXI Lite - Master write to slave
        procedure axi_write (constant address: in w12;
                             constant data:    in w32) is
        begin
            axi_awaddr  <= address;
            axi_awvalid <= '1';
            axi_wdata   <= data;
            axi_wvalid  <= '1';
            axi_wstrb   <= (others => '0');
            wait on axi_wready;
            
            axi_bready  <= '1';
            write_resp  <= axi_bresp;
            wait until rising_edge(axi_aclk);
            
            axi_bready  <= '0';
            axi_wvalid  <= '0';
            axi_awvalid <= '0';
            wait until rising_edge(axi_aclk);
        end procedure;

        constant addr_p_lsb : w12 := x"000"; 
        constant addr_p_msb : w12 := x"004";
        constant addr_c_lsb : w12 := x"008";
        constant addr_c_msb : w12 := x"00c";
        constant addr_k0_lsb: w12 := x"010";
        constant addr_k0_msb: w12 := x"014";
        constant addr_k_lsb : w12 := x"018";
        constant addr_k_msb : w12 := x"01c";
        constant addr_k1_lsb: w12 := x"020";
        constant addr_k1_msb: w12 := x"024";
    
        
        constant plain_text : w64 := x"0123456789ABCDEF";
        constant cipher_txt : w64 := x"85E813540F0AB405";
        constant crrct_key  : w56 := x"12695BC9B7B7F8";
        constant wrong_key1 : w56 := x"12695BC9B7B7EE"; -- 10 less than correct key
        constant wrong_key2 : w56 := x"12695BC9B7B794"; -- 100 less than correct key
        
        -- Test 1
        constant test1_input1: w32 := plain_text(1 to 32); 
        constant test1_input2: w32 := plain_text(33 to 64); 

    begin
        report "Test 1 start";
		axi_aresetn <= '0';
		for i in 1 to 2 loop
			wait until rising_edge(axi_aclk);
        end loop;
        axi_aresetn <= '1';

        -- Write p
        axi_write(addr_p_msb, plain_text(1 to 32));
        axi_write(addr_p_lsb, plain_text(33 to 64));
        
        -- Write c
        axi_write(addr_c_msb, cipher_txt(1 to 32));
        axi_write(addr_c_lsb, cipher_txt(33 to 64));
        
        -- Write k0
        axi_write(addr_k0_lsb, wrong_key1(25 to 56));
        axi_write(addr_k0_msb, x"00" & wrong_key1(1 to 24));
        
        -- Wait until cracker signals found key
        wait on irq;

        -- Check that lsb of found key is correct
        axi_read(addr_k1_lsb, read_data);
        assert read_data = crrct_key(25 to 56) report "Wrong lsb of found key" severity error;
        
        -- Check that msb of found key is correct
        axi_read(addr_k1_msb, read_data);
        assert read_data = x"00" & crrct_key(1 to 24) report "Wrong msb of found key" severity error;
        
        report "Test 2 start";
        axi_aresetn <= '0';
        for i in 1 to 2 loop
            wait until rising_edge(axi_aclk);
        end loop;
        axi_aresetn <= '1';

        -- Write p
        axi_write(addr_p_msb, plain_text(1 to 32));
        axi_write(addr_p_lsb, plain_text(33 to 64));
        
        -- Write c
        axi_write(addr_c_msb, cipher_txt(1 to 32));
        axi_write(addr_c_lsb, cipher_txt(33 to 64));
        
        -- Write k0, starting the cracker
        axi_write(addr_k0_lsb, wrong_key1(25 to 56));
        axi_write(addr_k0_msb, x"00" & wrong_key1(1 to 24));
        
        -- Wait 4 clock cycles (each cracking takes 1 cycle, and we need 10 to find)
        for i in 1 to 4 loop
            wait until rising_edge(axi_aclk);
        end loop;

        -- Write k0, stopping the cracker
        axi_write(addr_k0_lsb, wrong_key1(25 to 56));
        axi_write(addr_k0_msb, x"00" & wrong_key1(1 to 24));
        
        for i in 1 to 20 loop
            wait until rising_edge(axi_aclk);
        end loop;

        report "Test 3 start";
        axi_aresetn <= '0';
        for i in 1 to 2 loop
            wait until rising_edge(axi_aclk);
        end loop;
        axi_aresetn <= '1';

        wait until rising_edge(axi_aclk);
        
        axi_write(addr_k_lsb, plain_text(1 to 32));
        assert write_resp = axi_resp_SLVERR report "Writing to k does not return SLVERR" severity error;
        
        axi_write(addr_k1_msb, plain_text(1 to 32));
        assert write_resp = axi_resp_SLVERR report "Writing to k1 does not return SLVERR" severity error;

        axi_write(x"030", plain_text(1 to 32));
        assert write_resp = axi_resp_DECERR report "Writing outside address range does not return DECERR" severity error;

        axi_read(x"040", read_data);
        assert read_resp = axi_resp_DECERR report "Reading outside address range does not return DECERR" severity error;

        finish;
    end process test;
end architecture sim;
