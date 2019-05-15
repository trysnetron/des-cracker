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
    plain_txt   : in  w64;
    start_key   : in  w56;
    found_key   : out w64
);
end entity des_sm;

-- Setting up architecture of the des_sm --
architecture rtl of des_sm is
    
    signal k : w64; -- current key
    signal check1
begin
    /* 
    The thought is that we instantiate N key-checkers that start checking the  
    the start_key and the first N-1 keys after start_key. If every checker fails, 
    the keys are incremented by N, and the key-checkers continue checking keys. 
    If one checker succeds all the checkers are stopped. 
    */
    key_checker1 : entity work.des_key_checker(rtl)
    port map(
        clk         => clk
        sresetn     => sresetn,
        plain_txt   => plain_txt,
        key         => k,
        complete    => complete1,
        check       => check1
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if sresetn = '0' then
            
            else

            end if;
    end process;



end architecture rtl;










