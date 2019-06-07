--------------------------------------------------
--                                              --
--  Testbench for DES Cracker                   --
--  By Yohann Jacob Sandvik and Trym Sneltvedt  --
--                                              --
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity des_cracker_sim is
    generic(
        frequency_mhz: positive range 1 to 1000
    );
    port(
        irq:            out std_ulogic;
        led:            out std_ulogic_vector(3 downto 0)
    );
end entity des_cracker_sim;

architecture sim of des_cracker_sim is
    -- Typedefs
    subtype w12 is std_ulogic_vector(11 downto 0);
    subtype w32 is std_ulogic_vector(31 downto 0);
    subtype w56 is std_ulogic_vector(55 downto 0);
    subtype w64 is std_ulogic_vector(63 downto 0);
    
    -- Constants
    constant period:       time := (1.0e3 * 1 ns) / real(frequency_mhz);

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


    signal axi_aclk    : std_ulogic;        
    signal axi_aresetn : std_ulogic; 
    -- Read address channel signals
    signal axi_araddr  : w12; 
    signal axi_arvalid : std_ulogic;                     
    signal axi_arready : std_ulogic;                     
    -- Write address channel signals
    signal axi_awaddr  : w12; 
    signal axi_awvalid : std_ulogic;                     
    signal axi_awready : std_ulogic;                     
    -- Write data channel signals
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
    
    procedure axi_read(
        -- AXI Lite "master reads from slave" implementation

        -- function input
        signal aclk:     in  std_ulogic;
        signal address:  in  w12;
        -- master --> slave 
        signal araddr:   out w12;
        signal arvalid:  out std_ulogic; 
        signal rready:   out std_ulogic;
        -- slave --> master
        signal arready:  in  std_ulogic;
        signal rvalid:   in  std_ulogic;
        signal rdata:    in  std_ulogic_vector(31 downto 0);
        signal rresp:    in  std_ulogic_vector(1 downto 0);
        -- function output
        signal data:     out std_ulogic_vector(31 downto 0);
        signal response: out std_ulogic_vector(1 downto 0)
        ) is
    begin
        -- set the address we want to read from in   araddr
        araddr <= address;
        -- set address valid high                   arvalid
        arvalid <= '1';
        -- wait for acknowledge                     arready
        wait until rising_edge(aclk) and arready = '1' and rvalid  = '1';
        -- set read response acknowledge high
        rready <= '1';
        -- fetch data and response
        data     <= rdata;
        response <= rresp;

        wait until rising_edge(aclk);
        -- set read-ready-acknowledge low
        arvalid <= '0';
        rready <= '0';
    end procedure axi_read;

    procedure axi_write(
        -- function input
        signal aclk:    in  std_ulogic;
        signal address: in  w12; 
        signal data:    in  std_ulogic_vector(31 downto 0);
        -- master --> slave
        signal awaddr:  out std_ulogic_vector(11 downto 0);
        signal awvalid: out std_ulogic;
        signal wdata:   out std_ulogic_vector(31 downto 0);
        signal wstrb:   out std_ulogic_vector(3 downto 0);
        signal wvalid:  out std_ulogic;
        signal bready:  out std_ulogic;
        -- slave --> master
        signal awready: in  std_ulogic; 
        signal bresp:   in  std_ulogic_vector(1 downto 0);
        signal bvalid:  in  std_ulogic;
        signal wready:  in  std_ulogic;
        -- function output
        signal response:out std_ulogic_vector(1 downto 0)
        ) is
    begin
        -- set the address we want to write to in awaddr
        awaddr <= address;
        -- set address valid flag awvalid high 
        awvalid <= '1';
        -- put data in wdata field
        wdata <= data;
        -- set data valid flad wvalid high
        wvalid  <= '1';
        -- wait for acknowledge
        wait until rising_edge(aclk) and awready = '1' and wready  = '1' and bvalid  <= '1';
        -- get response and complete handshake. 
        response <= bresp;
        bready <= '1';

        wait until rising_edge(aclk);
        awvalid <= '0';
        wvalid  <= '0';

    end procedure axi_write;

    signal read_address:    w12;
    signal read_data:       w32;
    signal read_response:   std_ulogic_vector(1 downto 0);

    signal write_address:   w12;
    signal write_data:      w32;
    signal write_response:  std_ulogic_vector(1 downto 0); 

begin

    -- axi_read: process(aclk)
    -- begin
    --     axi_read(
    --         -- function input
    --         aclk        => aclk, 
    --         address     => read_address,
    --         -- master --> slave
    --         araddr      => araddr,
    --         address_v   => arvalid,
    --         arready     => arready,
    --         -- slave --> master
    --         rvalid      => rvalid,
    --         rdata       => rdata,
    --         rresp       => rresp,
    --         -- function output
    --         data        => read_data,
    --         response    => read_response
    --     );    
    -- end process axi_read;
    -- axi_write: process(aclk)
    -- begin
    --     axi_write(
    --         -- function input
    --         aclk        => aclk, 
    --         address     => write_address, 
    --         data        => write_data, 
    --         -- master --> slave
    --         awaddr      => awaddr,
    --         awvalid     => 
    --         wdata       => 
    --         wstrb       => 
    --         wvalid      => 
    --         bready      => 
    --         -- slave --> master
    --         awready     => 
    --         bresp       => 
    --         bvalid      => 
    --         wready      => 
    --         -- function output
    --         response    => write_response
    --     );
    -- end process axi_write;

    clock_process: process
    begin
        axi_aclk <= '0';
        wait for period / 2;
        axi_aclk <= '1';
        wait for period / 2;
    end process;

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

    tests: process
    begin
        report "I am a failure";
        finish(0);
    end process tests;
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

-- Test by writing p, c and k to the DES Cracker, waiting 
-- and retrieving the result.

-- p: 0123456789ABCDEF (Plain text)
-- c: 85E813540F0AB405 (Cipher text)
-- k: 12695BC9B7B7F8   (56-bit correct key) Not sure about this Trym? 


end architecture sim;
