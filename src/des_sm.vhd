-------------------------------------------------
---------------SM of DES-cracker-----------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

-- Setting up entity of des_sm --
entity sm is
generic(
    nr_engines : natural
);
port(
    clk         : in  std_ulogic;
    sresetn     : in  std_ulogic;
    crack_begin : in  std_ulogic;
    plain_txt   : in  w64;
    cipher_txt  : in  w64;
    start_key   : in  w56;
    current_key : out w56;
    found_key   : out w56;
    sm_complete : out std_ulogic
);
end entity sm;

-- Setting up architecture of the des_sm --
architecture rtl of sm is
    -- Defining signals for the SM
    type state_type is (IDLE, WORKING, CHECKING, KEY_INC, DONE);
    signal state : state_type;
    constant vector_of_ones : std_ulogic_vector(1 to nr_engines) := (others => '1');

    -- Signals controling SM
    signal complete : std_ulogic;
    signal check    : natural;

    -- Signals into checkers
    signal keys : key_vector(1 to nr_engines);
    signal checker_restart  : std_ulogic;

    -- Reset signal for all checkers
    signal checker_reset : std_ulogic;

    -- Signals out of checkers
    signal complete_vec     : std_ulogic_vector(1 to nr_engines);
    signal check_vec        : std_ulogic_vector(1 to nr_engines);

begin
    -- The thought is that we instantiate N key-checkers that start checking the  
    -- the start_key and the first N-1 keys after start_key. If every checker fails, 
    -- the keys are incremented by N, and the key-checkers continue checking keys. 
    -- If one checker succeds all the checkers are stopped. 

    -- Reset all checkers on either sresetn or checker_restart low
    checker_reset <= (sresetn and checker_restart);

    -- COMPLETE CHCK -------------------------------------------------------------
    check_for_completion: process(complete_vec)
    begin
        if complete_vec = vector_of_ones then 
            complete <= '1';
        else
            complete <= '0';
        end if;
    end process check_for_completion;

    -- ENGINE VECTOR -------------------------------------------------------------
    checker_vector: for i in 1 to nr_engines generate
        key_checker: entity work.des_key_checker(rtl)
        port map(
            clk         => clk,
            sresetn     => checker_reset,
            plain_txt   => plain_txt,
            correct_txt => cipher_txt,
            key         => keys(i),
            complete    => complete_vec(i),
            check       => check_vec(i)
        );
    end generate checker_vector;

    -- STATE MACHINE -------------------------------------------------------------
    state_machine: process(clk)
    begin 
        if rising_edge(clk) then
            if sresetn = '0' then 
                current_key <= (others => '0');
                found_key   <= (others => '0');
                sm_complete <= '1';
                keys <= (others => (others => '0'));
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if crack_begin = '1' then 
                            state <= WORKING;
                            keys <= initiate_keys(start_key, nr_engines);
                            sm_complete <= '0'; 
                        end if;
                    when WORKING =>
                        if complete = '1' then
                            state <= CHECKING;
                        end if;
                    when CHECKING =>
                        if unsigned(check_vec) > 0  then
                            for j in 1 to nr_engines loop
                                if check_vec(j) = '1' then
                                    found_key <= keys(j);
                                end if;
                            end loop;
                            state <= DONE; 
                        else
                            checker_restart <= '0'; 
                            current_key <= keys(nr_engines);
                            state <= KEY_INC;
                        end if;
                    when KEY_INC =>
                        if complete = '0' then
                            keys <= increment_keys(keys, nr_engines);
                            checker_restart <= '1';
                            state <= WORKING;
                        end if;
                    when DONE =>
                        sm_complete <= '1';
                end case;
            end if;
        end if;
    end process state_machine;

end architecture rtl;
