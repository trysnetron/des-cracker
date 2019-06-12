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
    clk     : in  std_ulogic;
    sresetn : in  std_ulogic;
    run     : in  std_ulogic;
    p       : in  w64;
    c       : in  w64;
    k0      : in  w56;
    k       : out w56;
    k1      : out w56;
    irq     : out std_ulogic
);
end entity sm;

architecture rtl of sm is
    type state_type is (IDLE, WORKING);
    signal state     : state_type := IDLE;
    signal k_vec     : key_vector(1 to nr_engines) := (others => (others => '0'));
    signal match_vec : std_ulogic_vector(1 to nr_engines) := (others => '0');
begin
    -- The thought is that we instantiate N key-checkers that start checking the  
    -- the start_key and the first N-1 keys after start_key. If every checker fails, 
    -- the keys are incremented by N, and the key-checkers continue checking keys. 
    -- If one checker succeds all the checkers are stopped. 

    -- ENGINE VECTOR -------------------------------------------------------------
    checker_vector: for i in 1 to nr_engines generate
        key_checker: entity work.des_engine(rtl)
        port map(
            p     => p,
            c     => c,
            k     => k_vec(i),
            match => match_vec(i)
        );
    end generate checker_vector;

    k <= k_vec(nr_engines);

    -- STATE MACHINE -------------------------------------------------------------
    state_machine: process(clk)
    begin 
        if rising_edge(clk) then
            irq <= '0';

            if sresetn = '0' then 
                k1    <= (others => '0');
                k_vec <= (others => (others => '0'));
                state <= IDLE;
            elsif run = '1' then
                case state is
                    when IDLE =>
                        if run = '1' then 
                            k_vec  <= initiate_keys(k0, nr_engines); 
                            state <= WORKING;
                        end if;
                    when WORKING =>
                        if unsigned(match_vec) > 0  then
                            for j in 1 to nr_engines loop
                                if match_vec(j) = '1' then
                                    k1    <= k_vec(j);
                                    irq   <= '1';
                                    if run = '0' then
                                        state <= IDLE; 
                                    end if;
                                end if;
                            end loop;
                        else
                            k_vec <= increment_keys(k_vec, nr_engines);
                            state <= WORKING;
                        end if;
                end case;
            end if;
        end if;
    end process state_machine;
end architecture rtl;
