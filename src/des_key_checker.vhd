-------------------------------------------------
----------------DES-key-checker------------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

-- Setting up entity of the key_checker --  
entity des_key_checker is
port(
    clk         : in  std_ulogic; 
    sresetn     : in  std_ulogic; -- synchronus active low reset
    plain_txt   : in  w64;
    key         : in  w56;
    correct_txt : in  w64;
    complete    : out std_ulogic; -- 1 if check is complete, 0 otherwise
    check       : out std_ulogic  -- 1 if we have found the correct key, 0 otherwise
);
end entity des_key_checker;

-- Setting up architecture of the des_key_checker --
architecture rtl of des_key_checker is
    
    signal engine_complete  : std_ulogic;
    signal cipher_txt       : w64;

begin 
    
    check_cipher_text: process(clk)
    begin
        if sresetn = '0' then 
            complete    <= '0';
            check       <= '0';
        else
            if engine_complete = '1' then
                if cipher_txt = correct_txt then
                    check <= '1';
                else
                    check <= '0';
                end if;
                complete <= '1';
            end if;
        end if;
    end process;

    engine: process(clk)
        variable acc : w64; -- Intermediate storage
        variable sk  : w768; -- All subkeys
    begin
        if rising_edge(clk) then
            if sresetn = '0' then
                cipher_txt      <= (others => '0');
                engine_complete <= '0';
            elsif complete /= '1' then
                sk := sub_key_gen(key); -- generates all subkeys for 16 iterations
                acc := ip(plain_txt);   -- initial permutation of plain text.
                for i in 0 to 15 loop
                    acc := des_step(sk(i*48 + 1 to (i + 1)*48 ), acc(1 to 32), acc(33 to 64));
                end loop;
                cipher_txt      <= iip(acc(33 to 64) & acc(1 to 32));
                engine_complete <= '1';
            end if;
        end if;
    end process;

end architecture rtl;
