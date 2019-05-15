library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;
use std.env.all; -- Neccesary to use the 'finish' command

-- declaring entity --
entity des_key_checker_sim is
port(
    check_out   : out std_ulogic;
    complete_out: out std_ulogic
);
end entity des_key_checker_sim;

-- declaring architecture -- 
architecture sim of des_key_checker_sim is

    constant period : time := (10 ns);
    constant plain_txt  : w64 := "0000000100100011010001010110011110001001101010111100110111101111";
    constant crt_key    : w64 := "0001001100110100010101110111100110011011101111001101111111110001";
    constant crt_cphr   : w64 := "1000010111101000000100110101010000001111000010101011010000000101";
    
    constant wrong_key_1 : w64 := "1001001100110100010101110111100110011011101111001101111111110001";
    constant wrong_key_2 : w64 := "0101001100110100010101110111100110011011101111001101111111110001";
    
    signal clk : std_ulogic;
    signal sresetn : std_ulogic;
    signal current_key : w64;
    signal complete : std_ulogic;
    signal check : std_ulogic;

begin

    process
    begin
        sresetn <= '0';

        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';
        
        sresetn <= '1';
        current_key <= wrong_key_1;

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

        sresetn <= '0';

        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';

        sresetn <= '1';
        current_key <= wrong_key_2;

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

        sresetn <= '0';

        wait for period / 2.0;
        clk <= '0';
        wait for period / 2.0;
        clk <= '1';

        sresetn <= '1';
        current_key <= crt_key;

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
        
        finish(2);
    end process;

    checker: entity work.des_key_checker(rtl)
    port map(
        clk         => clk,
        sresetn     => sresetn,
        plain_txt   => plain_txt,
        key         => current_key, 
        correct_txt => crt_cphr, 
        complete    => complete,
        check       => check
    );

    check_out <= check;
    complete_out <= complete;

end architecture sim;
