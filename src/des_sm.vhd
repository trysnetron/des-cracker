-------------------------------------------------
---------------SM of DES-cracker-----------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

-- Setting up entity of des_sm --
entity des_sm is
port(
    clk         : in  std_ulogic;
    sresetn     : in  std_ulogic;
    crck_begin  : in  std_ulogic;
    plain_txt   : in  w64;
    cipher_txt  : in  w64;
    start_key   : in  w56;
    found_key   : out w56;
    sm_complete : out std_ulogic
);
end entity des_sm;

-- Setting up architecture of the des_sm --
architecture rtl of des_sm is

    constant N: natural := 2; -- number of des_key_checkers instantiated
    type state_type is (IDLE, WORKING);    
    
    -- signals controling SM
    signal state: state_type; -- current state of SM
    signal complete: std_ulogic;
    signal check: std_ulogic;

    -- signals into checkers
    signal k: w64; -- current key
    signal checker_restart: std_ulogic;

    -- signals out of checkers
    signal check1: std_ulogic;
    signal complete1: std_ulogic;

    signal check2: std_ulogic;
    signal complete2: std_ulogic;

begin
    /* 
    The thought is that we instantiate N key-checkers that start checking the  
    the start_key and the first N-1 keys after start_key. If every checker fails, 
    the keys are incremented by N, and the key-checkers continue checking keys. 
    If one checker succeds all the checkers are stopped. 
    */
    complete <= complete1 and complete2;
    check <= check1 or check2;

    key_checker1 : entity work.des_key_checker(rtl)
    port map(
        clk         => clk
        sresetn     => sresetn and checker_restart,
        plain_txt   => plain_txt,
        correct_txt => cipher_txt,
        key         => k,
        complete    => complete1,
        check       => check1
    );

    key_checker2 : entity work.des_key_checker(rtl)
    port map(
        clk         => clk
        sresetn     => sresetn and checker_restart,
        plain_txt   => plain_txt,
        key         => increment_key(k,1),
        complete    => complete2,
        check       => check2
    );


    process(clk)
    begin
        if rising_edge(clk) then
            if sresetn = '0' then
                k <= (others => '0');
                state <= IDLE;
                sm_complete <= '0'; 
            else
                case state is
                    when IDLE =>
                        if crck_begin = '1' then
                            state <= WORKING;
                            k <= start_key;
                            checker_restart <= '1';
                            sm_complete <= '0'; 
                        end if;

                    when WORKING =>
                        checker_restart <= '0';
                        if complete = '1' then
                            if check = '1' then
                                if check1 = '1' then
                                    found_key <= k;
                                elsif check2 = '1' then
                                    found_key <= increment_key(k,1);
                                end if;
                                state <= IDLE;
                            else
                                checker_restart <= '1'; 
                                k <= increment_key(k,N);
                            end if;
                           sm_complete <= '1'; 
                        end if;
                end case;
            end if;
    end process;

end architecture rtl;


