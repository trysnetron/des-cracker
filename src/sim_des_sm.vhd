-------------------------------------------------
---------Tesbench of SM of DES-cracker-----------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;
use std.env.all; -- Neccesary to use the 'finish' command

entity des_sm_sim is
end entity des_sm_sim;

architecture sim of des_sm_sim is

    constant period     : time := 1 ns;
    constant plain_txt  : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant crt_key    : w56 := "00010010011010010101101111001001101101111011011111111000";
    -- constant crrct_key : w56 := x"12695BC9B7B7F8";
    constant start_key1  : w56 := "00010010011010010101101111001001101101111011011111110101"; -- 03 less than correct key
    constant start_key2  : w56 := "00010010011010010101101111001001101101111011011111101000"; -- 16 less than correct key
    constant crt_cphr    : w64 := "1000010111101000000100110101010000001111000010101011010000000101";
    
    signal clk           : std_ulogic;
    signal sresetn       : std_ulogic;
    signal crack_begin   : std_ulogic;
    signal sm_complete   : std_ulogic;
    signal found_key     : w56;
    signal current_key   : w56;
    signal input_key     : w56 := start_key2;
begin
    -- Entities
    sm: entity work.sm(rtl)
    generic map(
        nr_engines  => 8
    )
    port map(
        clk     => clk,    
        sresetn => sresetn,
        run     => crack_begin,
        p       => plain_txt,
        c       => crt_cphr,
        k0      => input_key,
        k       => current_key,
        k1      => found_key,
        irq     => sm_complete
    );

    clock: process
    begin
        clk <= '1';
        wait for period / 2;
        clk <= '0';                     
        wait for period / 2;
    end process clock;

    tests: process
    begin
        crack_begin <= '0';
        sresetn <= '0';
        input_key <= start_key2;
        for i in 1 to 3 loop
            wait until rising_edge(clk);
        end loop;
        sresetn <= '1';
        crack_begin <= '1';
        wait until rising_edge(clk);
        wait on sm_complete;
        
        wait until rising_edge(clk);
        assert found_key = crt_key report "SM did not find correct key" severity error;
        
        sresetn <= '0';
        crack_begin <= '0';
        input_key <= crt_key;
        for i in 1 to 3 loop
            wait until rising_edge(clk);
        end loop;
        sresetn <= '1';
        crack_begin <= '1';
        wait until rising_edge(clk);
        
        wait on sm_complete;
        assert found_key = crt_key report "SM could not detect first key" severity error;
        for i in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;

        finish;
    end process tests;

end architecture sim;
