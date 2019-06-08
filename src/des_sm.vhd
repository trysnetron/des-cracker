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
generic(nr_engines : natural);
port(
    clk         : in  std_ulogic;
    sresetn     : in  std_ulogic;
    crck_begin  : in  std_ulogic;
    crck_end    : in  std_ulogic;
    plain_txt   : in  w64;
    cipher_txt  : in  w64;
    start_key   : in  w56;
    current_key : out w56;
    found_key   : out w56;
    sm_complete : out std_ulogic
);
end entity des_sm;

-- Setting up architecture of the des_sm --
architecture rtl of des_sm is

    type state_type is (IDLE, WORKING);    
    constant vector_of_ones : std_ulogic_vector(1 to nr_engines) := (others => '1');
    -- Signals controling SM
    signal state:    state_type; -- current state of SM
    signal complete: std_ulogic;
    signal check:    natural;

    -- Signals into checkers
    signal keys : key_vector(1 to nr_engines);
    signal checker_restart  : std_ulogic;

    -- Signals out of checkers
    signal complete_vec     : std_ulogic_vector(1 to nr_engines);
    signal check_vec        : std_ulogic_vector(1 to nr_engines);

begin
     
    -- The thought is that we instantiate N key-checkers that start checking the  
    -- the start_key and the first N-1 keys after start_key. If every checker fails, 
    -- the keys are incremented by N, and the key-checkers continue checking keys. 
    -- If one checker succeds all the checkers are stopped. 
    check_for_completion: process(complete_vec)
    begin
        if complete_vec = vector_of_ones then 
            complete <= '1';
        else
            complete <= '0';
        end if;
    end process check_for_completion;

    check_for_correct_key: process(complete)
    begin
        check <= 0;
        for j in 1 to nr_engines loop
            if check_vec(j) = '1' then
                check <= j;
            end if;
        end loop;
    end process check_for_correct_key;

    checker_vector:
    for i in 1 to nr_engines generate
        key_checker: entity work.des_key_checker(rtl)
        port map(
            clk         => clk,
            sresetn     => (sresetn and checker_restart),
            plain_txt   => plain_txt,
            correct_txt => cipher_txt,
            key         => keys(i),
            complete    => complete_vec(i),
            check       => check_vec(i)
        );
    end generate checker_vector;

    process(clk)
    begin
        if rising_edge(clk) then
            if sresetn = '0' then
                state <= IDLE;
                sm_complete <= '0'; 
                keys <= (others => (others => '0'));
            else
                case state is
                    when IDLE =>
                        if crck_begin = '1' and sm_complete then 
                            state <= WORKING;
                            keys <= initiate_keys(start_key, nr_engines);
                            checker_restart <= '0'; -- Active low
                            sm_complete <= '0'; 
                        end if;
                    when WORKING =>
                        if crck_end = '1' then
                            state           <= IDLE;
                            checker_restart <= '0';
                            keys <= (others => (others => '0'));
                            found_key <= (others => '0'); 
                        else
                            checker_restart <= '1';
                            if complete = '1' then
                                if check /= 0  then
                                    found_key <= keys(check);
                                    state <= IDLE; 
                                    sm_complete <= '1'; 
                                else
                                    checker_restart <= '0'; 
                                    current_key <= keys(nr_engines);
                                    keys <= increment_keys(keys, nr_engines);
                                end if;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;


