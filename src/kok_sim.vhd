library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

entity kok_engine_sim is

end entity kok_engine_sim;

architecture sim of kok_engine_sim is

    clk	    	: std_ulogic;	-- Master clock.
	aresetn		: std_ulogic;	-- Sync. AXI. Reset.
	p		    : w64;		    -- Plaintext.
	c		    : w64;		    -- Ciphertext.
	k0		    : w56;		    -- Starting key.
	start_crack	: std_ulogic;	-- Start state machine.
	k		    : w56;		    -- Current key.
	irq		    : std_ulogic 	-- Cracking complete flag

begin

    kok_engine: entity work.des_cracker_small(rtl)
    port map(
        aclk 	=> clk,
        aresetn => aresetn,
        p 		=> p,
        c 		=> c,
        k0 		=> k0,
        start_crack => start_crack,
        k 		=> k,
        irq	 	=> irq
    );

end architecture sim;