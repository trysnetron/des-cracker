-------------------------------------------------
--------------16-step DES-engine-----------------
---by Trym Sneltvedt, and Yohann Jacob Sandvik---
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

-- Setting up entity of the engine --  
entity des_engine is
port(
    clk         : in  std_ulogic; -- axi4 clock from one of the cortex CPUs
    sresetn     : in  std_ulogic; -- **synchronous** active **low** reset from CPU part of Zynq core (the leading _a_ means AXI, not asynchronous)
    plain_txt   : in  w64;
    key         : in  w64;
    cipher_txt  : out w64
);
end entity des_engine;

-- Setting up architecture of the des_engine --
architecture rtl of des_engine is
    

begin 
    
    process(clk)
        variable acc: w64; -- Intermediate storage
        variable sk: w768; -- subkeys
    begin
        if rising_edge(clk) then
            if sresetn = '0' then
                cipher_txt <= (others => '0');
            else
                sk := sub_key_gen(key);
                acc := ip(plain_txt);
                for i in 0 to 15 loop
                    acc := des_step(sk(i*48 + 1 to (i + 1)*48 ), acc(1 to 32), acc(33 to 64));
                end loop;
                cipher_txt <= iip(acc(33 to 64) & acc(1 to 32));
            end if;
        end if;
    end process;

end architecture rtl;
