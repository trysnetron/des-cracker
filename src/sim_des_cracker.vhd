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
            wait until rising_edge(axi_aclk);
            
            axi_bready  <= '0';
            axi_wvalid  <= '0';
            axi_awvalid <= '0';
            wait until rising_edge(axi_aclk);
            -- assert axi_bresp = axi_resp_OKAY report "Write did not return OKAY" severity note;
        end procedure;

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
        

        for i in 1 to 15 loop
            wait until rising_edge(axi_aclk);
        end loop;
        
        -- axi_write(addr_p_lsb, test1_input2);
        
        
        finish;
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
		
	end process test;
end architecture sim;
