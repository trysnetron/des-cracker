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
port(
    f_key       : out w56;
    sim_complete: out std_ulogic
);
end entity des_sm_sim;

architecture sim of des_sm_sim is

    constant period     : time := (10 ns);
    constant plain_txt  : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant crt_key    : w56 := "00010010011010010101101111001001101101111011011111111000";
    constant start_key  : w56 := "00010010011010010101101111001001101101111011011111110101"; -- Three less than correct key
    constant crt_cphr   : w64 := "1000010111101000000100110101010000001111000010101011010000000101";
    
    signal clk          : std_ulogic;
    signal sresetn      : std_ulogic;
    signal crack_begin  : std_ulogic;
    signal found_key    : w56;
    signal complete     : std_ulogic;
    signal check        : std_ulogic;
    signal current_key  : w56;

begin
    -- Entities
    sm: entity work.des_sm(rtl)
    generic map(
        nr_engines  => 2
    )
    port map(
        clk         => clk,    
        sresetn     => sresetn,
        crck_begin  => crack_begin,
        crck_end    => '0',
        plain_txt   => plain_txt,
        cipher_txt  => crt_cphr,
        start_key   => start_key,
        current_key => current_key,
        found_key   => found_key,
        sm_complete => complete
    );

    -- Processes
    f_key           <= found_key;
    sim_complete    <= complete;

    clock: process
    begin
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';                     
        sresetn <= '0';
        wait for period / 2.0;
        sresetn <= '1';
        crack_begin <= '1';

        for i in 1 to 15 loop
            clk <= '0';
            wait for period / 2.0;
            clk <= '1';                     
            wait for period / 2.0;
        end loop;
        finish;
    end process clock;

end architecture sim;
