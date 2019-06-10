-------------------------------------------------
---------------   DES-engine   ------------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

entity des_engine is
port(
    clk         : in  std_ulogic; -- clock
    sresetn     : in  std_ulogic; -- synchronys active low reset
    plaintext   : in  w64; -- Plaintext to be encrypted
    key         : in  w56; -- Key to use for encryption
    ciphertext  : in  w64; -- Ciphertext to compare with encryption
    complete    : out std_ulogic; -- Complete flag
    success     : out std_ulogic -- Success flag
);
end entity des_engine;

architecture rtl of des_engine is

    type states is (INITIAL, ENCRYPTING, FINAL, FINISHED);
    signal state : states;

    signal round_nr: positive := 1;

    signal ciphertext_local : w64 := (others => '0');
    --signal C_n  : w28;
    --signal D_n  : w28;
    signal acc    : w64;
    signal subkey : w56;
begin 
    sm: process(clk)
    begin
        if rising_edge(clk) then
            complete <= '0';
            success  <= '0';
            if sresetn = '0' then
                round_nr <= 1;
                state    <= INITIAL;
            else
                case state is
                    when INITIAL =>
                        -- setting signals
                        ciphertext_local <= ciphertext;
                        -- beginning
                        acc    <= ip(plaintext);
                        subkey <= sub_key_step(key, 1);
                        state  <= ENCRYPTING;
                        
                    when ENCRYPTING =>
                        acc <= des_step(pc2(subkey), acc(1 to 32), acc(33 to 64));
                        if round_nr < 16 then
                            round_nr <= round_nr + 1;
                            if round_nr = 1 or round_nr = 2 or round_nr = 9 or round_nr = 16 then
                                subkey <= left_shift(subkey(1 to 28), 1) & left_shift(subkey(29 to 56), 1);
                            else 
                                subkey <= left_shift(subkey(1 to 28), 2) & left_shift(subkey(29 to 56), 2);
                            end if;
                        else
                            state <= FINAL;
                        end if;
                    
                    when FINAL =>
                        acc <= iip(acc(33 to 64) & acc(1 to 32));
                        state <= FINISHED;
                    
                    when FINISHED =>
                        if  acc = ciphertext_local then
                            success <= '1';
                        end if;
                        complete <= '1';
                end case;
            end if;
        end if;
    end process sm;

    --complete <= complete_local; 
--
    --check_cipher_text: process(clk)
    --begin
    --    if rising_edge(clk) then
    --        complete_local <= '0';
    --        if sresetn = '0' then 
    --            check <= '0';
    --        else
    --            if engine_complete = '1' then
    --                if cipher_txt = correct_txt then
    --                    check <= '1';
    --                else
    --                    check <= '0';
    --                end if;
    --                complete_local <= '1';
    --            end if;
    --        end if;
    --    end if;
    --end process;
--
    --engine: process(clk)
    --    variable acc : w64; -- Intermediate storage
    --    variable sk  : w768; -- All subkeys
    --begin
    --    if rising_edge(clk) then
    --        if sresetn = '0' then
    --            cipher_txt      <= (others => '0');
    --            engine_complete <= '0';
    --        elsif complete_local /= '1' then
    --            sk := sub_key_gen(key); -- generates all subkeys for 16 iterations
    --            acc := ip(plain_txt);   -- initial permutation of plain text.
    --            for i in 0 to 15 loop
    --                acc := des_step(sk(i*48 + 1 to (i + 1)*48 ), acc(1 to 32), acc(33 to 64));
    --            end loop;
    --            cipher_txt      <= iip(acc(33 to 64) & acc(1 to 32));
    --            engine_complete <= '1';
    --        end if;
    --    end if;
    --end process;
end architecture rtl;
