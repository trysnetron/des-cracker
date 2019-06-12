-------------------------------------------------
----------------DES-key-checker------------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.des_pkg.all;

entity des_engine is
port(
    p     : in  w64;        -- Plaintext
    k     : in  w56;        -- Key
    c     : in  w64;        -- Ciphertext
    match : out std_ulogic  -- Ciphertext matches des(plaintext, key)
);
end entity des_engine;

architecture rtl of des_engine is
begin 
    match <= '1' when des(p, k) = c else '0'; 
end architecture rtl;
