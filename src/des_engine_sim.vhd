library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;
use std.env.all; -- Neccesary to use the 'finish' command

entity des_engine_sim is
port(
    ciph : out w64 
);
end entity des_engine_sim;

architecture sim of des_engine_sim is

    constant period : time := (10 ns);
    constant plain_txt : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant key : w64 := "0001001100110100010101110111100110011011101111001101111111110001";
    
    signal clk : std_ulogic;
    signal sresetn : std_ulogic;
    signal cipher_txt : w64;
    signal complete : std_ulogic;

begin

    process
    begin
        sresetn <= '0';
        wait for period;
        sresetn <= '1';
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';
        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';
        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';
        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';
        wait for period / 2.0;

        finish(2);
    end process;

    engine: entity work.des_engine16(rtl)
    port map(
        clk         => clk,
        sresetn     => sresetn,
        plain_txt   => plain_txt,
        key         => key, 
        cipher_txt  => cipher_txt,
        complete    => complete
    );

    ciph <= cipher_txt;


end architecture sim; 
