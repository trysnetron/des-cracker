library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package des_pkg is
    subtype w28 is std_ulogic_vector(1 to 28);
    subtype w32 is std_ulogic_vector(1 to 32);
    subtype w48 is std_ulogic_vector(1 to 48);
    subtype w56 is std_ulogic_vector(1 to 56);
    subtype w64 is std_ulogic_vector(1 to 64);
    subtype w728 is std_ulogic_vector(1 to 768);

    type ip_t is array(1 to 64) of natural range 1 to 64;
    type pc1_t is array(1 to 56) of natural range 1 to 64;
    type pc2_t is array(1 to 48) of natural range 1 to 56;

    constant ip_table : ip_t := (
        58, 50, 42, 34, 26, 18, 10,  2, 
        60, 52, 44, 36, 28, 20, 12,  4,
        62, 54, 46, 38, 30, 22, 14,  6,
        64, 56, 48, 40, 32, 24, 16,  8,
        57, 49, 41, 33, 25, 17,  9,  1,
        59, 51, 43, 35, 27, 19, 11,  3,
        61, 53, 45, 37, 29, 21, 13,  5,
        63, 55, 47, 39, 31, 23, 15,  7
    );

    constant pc1_table : pc1_t := (
        57, 49, 41, 33, 25, 17, 9,
         1, 58, 50, 42, 34, 26, 18,
        10,  2, 59, 51, 43, 35, 27,
        19, 11,  3, 60, 52, 44, 36,
        63, 55, 47, 39, 31, 23, 15,
         7, 62, 54, 46, 38, 30, 22,
        14,  6, 61, 53, 45, 37, 29,
        21, 13,  5, 28, 20, 12,  4
    );
    constant pc2_table : pc2_t := (
        14, 17, 11, 24,  1,  5,
         3, 28, 15,  6, 21, 10,
        23, 19, 12,  4, 26,  8,
        16,  7, 27, 20, 13,  2,
        41, 52, 31, 37, 47, 55,
        30, 40, 51, 45, 33, 48,
        44, 49, 39, 56, 34, 53,
        46, 42, 50, 36, 29, 32
    );
    
    function left_shift(w:w28; amount:natural) return w28;
    function right_shift(w:w28; amount:natural) return w28;
    function sub_key_gen(key:w64) return w728;

    -- function p(w:w32) return w32;
    -- function f(r:w32; rk: w48) return w32;
    -- function des(p:w64; k:w64) return w64;
    function ip(w:w64) return w64;

end package des_pkg;

package body des_pkg is 
    
    function sub_key_gen(key:w64) return w728 is -- Returns all subkeys concatenated to one long bit vector of length 728
        variable permuted_key:w56;
        variable c:w28;
        variable d:w28;
        variable concatenated_pair:w56;
        variable result:w728;

    begin
        -- permuting key according to table PC-1
        for i in 1 to 56 loop
            permuted_key(i) := key(pc1_table(i));
        end loop;
        -- Generating subkeys
        c := permuted_key(1 to 28);
        d := permuted_key(29 to 56);
        for i in 1 to 16 loop
            if i = 1 or i = 2 or i = 9 or i = 16 then
                c := left_shift(c, 1);
                d := left_shift(d, 1);
            else 
                c := left_shift(c, 2);
                d := left_shift(d, 2);
            end if;
            concatenated_pair := c & d;
            for j in 1 to 48 loop
                result((i - 1)*48 + j) := concatenated_pair(pc2_table(j));
            end loop;
        end loop;
        return result;
    end function;

    function left_shift(w:w28; amount:natural) return w28 is
        begin
        if amount = 2 then
            return w(3 to 28) & w(1 to 2);
        elsif amount = 1 then
            return w(2 to 28) & w(1);
        else
            assert false report "ERROR" severity failure;
        end if;
    end left_shift;


    function right_shift(w:w28; amount:natural) return w28 is
        begin
        if amount = 2 then
            return w(27 to 28) & w(1 to 26);
        elsif amount = 1 then
            return w(28) & w(1 to 27);
        else
            assert false report "ERROR" severity failure;
        end if;
    end right_shift;


    function ip(w:w64) return w64 is
        variable result:w64;
    begin
        for i in 1 to 64 loop
            result(i) := w(ip_table(i));
        end loop;
        return result;
    end function;

end package body des_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
