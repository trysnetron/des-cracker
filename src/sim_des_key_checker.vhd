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
    constant crt_key    : w56 := "00010010011010010101101111001001101101111011011111111000";
    constant crt_cphr   : w64 := "1000010111101000000100110101010000001111000010101011010000000101";
    
    constant wrong_key_1 : w56 := "10010010011010010101101111001001101101111011011111111000";
    constant wrong_key_2 : w56 := "01010010011010010101101111001001101101111011011111111000";
    
    signal clk : std_ulogic;
    signal sresetn : std_ulogic;
    signal current_key : w56;
    signal complete : std_ulogic;
    signal check : std_ulogic;

begin

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

    clock: process
    begin
        for i in 1 to 30 loop
            wait for period / 2.0;
            clk <= '0';
            wait for period / 2.0;
            clk <= '1';
        end loop;
    end process clock;

    tests: process
    begin
        sresetn <= '0';

        wait for period;
        
        sresetn <= '1';
        current_key <= wrong_key_1;

        wait until complete = '1';
        wait for period;
        if check = '0' then
            report "DID NOT THINK WRONG KEY 1 WAS THE CORRECT KEY";
        end if;

        sresetn <= '0';

        wait for period;

        sresetn <= '1';
        current_key <= wrong_key_2;

        wait until complete = '1';
        wait for period;
        if check = '0' then
            report "DID NOT THINK WRONG KEY 2 WAS THE CORRECT KEY";
        end if;

        sresetn <= '0';

        wait for period;

        sresetn <= '1';
        current_key <= crt_key;

        wait until complete = '1';
        if check = '0' then
            report "DID NOT THINK CORRECT KEY WAS THE CORRECT KEY";
        else
            report "IDENTIFIED CORRECT KEY"; 
        end if;
        
        wait for 2*period;
        finish;
    end process;

end architecture sim;
