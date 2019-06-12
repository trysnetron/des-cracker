library ieee;
use ieee.std_logic_1164.all;
use work.des_pkg.all;
use std.env.all; -- Neccesary to use the 'finish' command

-- declaring entity --
entity des_engine_sim is
end entity des_engine_sim;

-- declaring architecture -- 
architecture sim of des_engine_sim is

    constant period : time := (10 ns);
    constant plain_txt  : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant crt_cphr   : w64 := "1000010111101000000100110101010000001111000010101011010000000101";
    constant crt_key    : w56 := "00010010011010010101101111001001101101111011011111111000";
    constant wrong_key_1 : w56 := "10010010011010010101101111001001101101111011011111111000";
    constant wrong_key_2 : w56 := "01010010011010010101101111001001101101111011011111111000";
    
    signal p : w64;
    signal k : w56;
    signal c : w64;
    signal match : std_ulogic;

begin

    u_engine: entity work.des_engine(rtl)
    port map(
        p     => p,
        k     => k,
        c     => c,
        match => match
    );

    tests: process
    begin
        
        p <= plain_txt;
        c <= crt_cphr;
        k <= wrong_key_1;
        wait for 1 ns;
        assert match = '0' report "engine matched wrong key 1" severity error;
        
        k <= wrong_key_2;
        wait for 1 ns;
        assert match = '0' report "engine matched wrong key 2" severity error;
        
        k <= crt_key;
        wait for 1 ns;
        assert match = '1' report "engine did not match correct key" severity error;

        wait for 1 ns;
        finish;
    end process;

end architecture sim;
