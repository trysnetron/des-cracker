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
    aresetn        : in  std_ulogic;                     -- **synchronous** active **low** reset from CPU part of Zynq core (the leading _a_ means AXI, not asynchronous)
    s0_axi_araddr  : in  std_ulogic_vector(11 downto 0); -- read address from CPU (12 bits = 4kB)                                                                        
    s0_axi_arvalid : in  std_ulogic;                     -- read address valid from CPU                                                                                  
    s0_axi_arready : out std_ulogic;                     -- read address acknowledge to CPU                                                                              
    s0_axi_awaddr  : in  std_ulogic_vector(11 downto 0); -- write address from CPU (12 bits = 4kB)                                                                       
    s0_axi_awvalid : in  std_ulogic;                     -- write address valid flag from CPU                                                                            
    s0_axi_awready : out std_ulogic;                     -- write address acknowledge to CPU                                                                             
    s0_axi_wdata   : in  std_ulogic_vector(31 downto 0); -- write data from CPU                                                                                          
    s0_axi_wstrb   : in  std_ulogic_vector(3 downto 0);  -- write byte enables from CPU                                                                                  
    s0_axi_wvalid  : in  std_ulogic;                     -- write data and byte enables valid from CPU                                                                   
    s0_axi_wready  : out std_ulogic;                     -- write data and byte enables acknowledge to CPU                                                               
    s0_axi_rdata   : out std_ulogic_vector(31 downto 0); -- read data response to CPU                                                                                    
    s0_axi_rresp   : out std_ulogic_vector(1 downto 0);  -- read status response (OKAY, EXOKAY, SLVERR or DECERR) to CPU                                                 
    s0_axi_rvalid  : out std_ulogic;                     -- read data and status response valid flag to CPU                                                              
    s0_axi_rready  : in  std_ulogic;                     -- read response acknowledge from CPU                                                                           
    s0_axi_bresp   : out std_ulogic_vector(1 downto 0);  -- write status response (OKAY, EXOKAY, SLVERR or DECERR) to CPU                                                
    s0_axi_bvalid  : out std_ulogic;                     -- write status response valid to CPU                                                                           
    s0_axi_bready  : in  std_ulogic;                     -- write response acknowledge from CPU                                                                          
    irq            : out std_ulogic;                     -- interrupt request to CPU                                                                                     
    led            : out std_ulogic_vector(3 downto 0);  -- wired to the four user LEDs                                                                                  
);
end entity des_cracker;

-- Setting up architecture of the des_cracker
architecture rtl of des_cracker is

    signal p   : std_ulogic_vector(63 downto 0); -- The plaintext           base adress: 0x000
    signal c   : std_ulogic_vector(63 downto 0); -- The ciphertext          base adress: 0x008
    signal k0  : std_ulogic_vector(55 downto 0); -- The starting secret key base adress: 0x010
    signal k   : std_ulogic_vector(55 downto 0); -- The current secret key  base adress: 0x018
    signal k1  : std_ulogic_vector(55 downto 0); -- The found secret key    base adress: 0x020

begin 
end architecture rtl;
