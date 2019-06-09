library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;
use std.env.all; -- Neccesary to use the 'finish' command

entity des_engine_sim is
end entity des_engine_sim;

architecture sim of des_engine_sim is

    constant period   : time := 1 ns;
    
    signal clk        : std_ulogic;
    signal sresetn    : std_ulogic;
    signal plaintext  : w64;
    signal key        : w56;
    signal ciphertext : w64;
    signal complete   : std_ulogic;
    signal success    : std_ulogic;
    
begin

    engine: entity work.des_engine(rtl)
    port map(
        clk         => clk,
        sresetn     => sresetn,
        plaintext   => plaintext,
        key         => key, 
        ciphertext  => ciphertext,
        complete    => complete,
        success     => success
    );

    clock: process 
    begin
        clk <= '0';
        wait for period / 2;
        clk <= '1';
        wait for period / 2; 
    end process clock;

    test: process
        constant test1_p : w64 := x"0123456789ABCDEF";
        constant test1_k : w56 := x"12695BC9B7B7F8";
        constant test1_c : w64 := x"85E813540F0AB405";
        
        constant test2_p : w64 := x"0123456789ABCDEF";
        constant test2_k : w56 := x"12695BC9B7B7F8";
        constant test2_c : w64 := x"85E813540F0AB404"; -- Wrong cipher
    begin
        -- Test 1: Check is the engine can signal the cipher to be correct
        sresetn <= '0';
        wait until rising_edge(clk);
        
        plaintext  <= test1_p;
        key        <= test1_k;
        ciphertext <= test1_c;

        sresetn <= '1';
        for i in 1 to 20 loop
            wait until rising_edge(clk);
        end loop;
        
        assert success = '1' report "Correct key not detected" severity error;

        -- Test 2: Check if the engine can signal an almost correct key as wrong key
        sresetn <= '0';
        wait until rising_edge(clk);
        
        plaintext  <= test2_p;
        key        <= test2_k;
        ciphertext <= test2_c;

        sresetn <= '1';
        for i in 1 to 20 loop
            wait until rising_edge(clk);
        end loop;

        assert success = '0' report "False positive" severity error;

        finish;
    end process;

end architecture sim; 
