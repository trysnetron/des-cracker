library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package des_pkg is
    subtype w4 is std_ulogic_vector(1 to 4);
    subtype w6 is std_ulogic_vector(1 to 6);
    subtype w28 is std_ulogic_vector(1 to 28);
    subtype w32 is std_ulogic_vector(1 to 32);
    subtype w48 is std_ulogic_vector(1 to 48);
    subtype w56 is std_ulogic_vector(1 to 56);
    subtype w64 is std_ulogic_vector(1 to 64);
    subtype w728 is std_ulogic_vector(1 to 768);

    type ip_t is array(1 to 64) of natural range 1 to 64;
    type pc1_t is array(1 to 56) of natural range 1 to 64;
    type pc2_t is array(1 to 48) of natural range 1 to 56;
    type es_t is array(1 to 48) of natural range 1 to 32;
    type s_t is array(0 to 63) of natural range 0 to 15;

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

    constant e_sel_table : es_t := (
        32,  1,  2,  3,  4,  5,
         4,  5,  6,  7,  8,  9,
         8,  9, 10, 11, 12, 13,
        12, 13, 14, 15, 16, 17,
        16, 17, 18, 19, 20, 21,
        20, 21, 22, 23, 24, 25,
        24, 25, 26, 27, 28, 29,
        28, 29, 30, 31, 32,  1
    );

    constant s_1 : s_t := (
        14,  4, 13,  1,  2, 15, 11,  8,  3, 10,  6, 12,  5,  9,  0,  7,
         0, 15,  7,  4, 14,  2, 13,  1, 10,  6, 12, 11,  9,  5,  3,  8,
         4,  1, 14,  8, 13,  6,  2, 11, 15, 12,  9,  7,  3, 10,  5,  0,
        15, 12,  8,  2,  4,  9,  1,  7,  5, 11,  3, 14, 10,  0,  6, 13
    );
    constant s_2 : s_t := (
        15,  1,  8, 14,  6, 11,  3,  4,  9,  7,  2, 13, 12,  0,  5, 10,
         3, 13,  4,  7, 15,  2,  8, 14, 12,  0,  1, 10,  6,  9, 11,  5,
         0, 14,  7, 11, 10,  4, 13,  1,  5,  8, 12,  6,  9,  3,  2, 15,
        13,  8, 10,  1,  3, 15,  4,  2, 11,  6,  7, 12,  0,  5, 14,  9 
    );
    constant s_3 : s_t := (
        10,  0,  9, 14,  6,  3, 15,  5,  1, 13, 12,  7, 11,  4,  2,  8,
        13,  7,  0,  9,  3,  4,  6, 10,  2,  8,  5, 14, 12, 11, 15,  1,
        13,  6,  4,  9,  8, 15,  3,  0, 11,  1,  2, 12,  5, 10, 14,  7,
         1, 10, 13,  0,  6,  9,  8,  7,  4, 15, 14,  3, 11,  5,  2, 12
    );
    constant s_4 : s_t := (
         7, 13, 14,  3,  0,  6,  9, 10,  1,  2,  8,  5, 11, 12,  4, 15,
        13,  8, 11,  5,  6, 15,  0,  3,  4,  7,  2, 12,  1, 10, 14,  9,
        10,  6,  9,  0, 12, 11,  7, 13, 15,  1,  3, 14,  5,  2,  8,  4,
         3, 15,  0,  6, 10,  1, 13,  8,  9,  4,  5, 11, 12,  7,  2, 14 
    );
    constant s_5 : s_t := (
         2, 12,  4,  1,  7, 10, 11,  6,  8,  5,  3, 15, 13,  0, 14,  9,
        14, 11,  2, 12,  4,  7, 13,  1,  5,  0, 15, 10,  3,  9,  8,  6,
         4,  2,  1, 11, 10, 13,  7,  8, 15,  9, 12,  5,  6,  3,  0, 14,
        11,  8, 12,  7,  1, 14,  2, 13,  6, 15,  0,  9, 10,  4,  5,  3 
    );
    constant s_6 : s_t := (
        12,  1, 10, 15,  9,  2,  6,  8,  0, 13,  3,  4, 14,  7,  5, 11,
        10, 15,  4,  2,  7, 12,  9,  5,  6,  1, 13, 14,  0, 11,  3,  8,
         9, 14, 15,  5,  2,  8, 12,  3,  7,  0,  4, 10,  1, 13, 11,  6,
         4,  3,  2, 12,  9,  5, 15, 10, 11, 14,  1,  7,  6,  0,  8, 13 
    );
    constant s_7 : s_t := (
         4, 11,  2, 14, 15,  0,  8, 13,  3, 12,  9,  7,  5, 10,  6,  1,
        13,  0, 11,  7,  4,  9,  1, 10, 14,  3,  5, 12,  2, 15,  8,  6,
         1,  4, 11, 13, 12,  3,  7, 14, 10, 15,  6,  8,  0,  5,  9,  2,
         6, 11, 13,  8,  1,  4, 10,  7,  9,  5,  0, 15, 14,  2,  3, 12
    );
    constant s_8 : s_t := (
        13,  2,  8,  4,  6, 15, 11,  1, 10,  9,  3, 14,  5,  0, 12,  7,
         1, 15, 13,  8, 10,  3,  7,  4, 12,  5,  6, 11,  0, 14,  9,  2,
         7, 11,  4,  1,  9, 12, 14,  2,  0,  6, 10, 13, 15,  3,  5,  8,
         2,  1, 14,  7,  4, 10,  8, 13, 15, 12,  9,  0,  3,  5,  6, 11 
    );
    
    function left_shift(w:w28; amount:natural) return w28;
    function right_shift(w:w28; amount:natural) return w28;
    function sub_key_gen(key:w64) return w728;
    function feistel(R:w32; K:w48) return w32;
    function s_map(a:w6; s:s_t) return w4;
    
    -- function p(w:w32) return w32;
    -- function f(r:w32; rk: w48) return w32;
    -- function des(p:w64; k:w64) return w64;
    function ip(w:w64) return w64;
    function ebs(w:w32) return w48;

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

    function feistel(R:w32; K:w48) return w32 is
        variable temp:w48;
        variable result:w32;
    begin
        temp := ebs(R) xor K;
        
        result( 1 to  4) := s_map(temp( 1 to  6), s_1);
        result( 5 to  8) := s_map(temp( 7 to 12), s_2);
        result( 9 to 12) := s_map(temp(13 to 18), s_3);
        result(13 to 16) := s_map(temp(19 to 24), s_4);
        result(17 to 20) := s_map(temp(25 to 30), s_5);
        result(21 to 24) := s_map(temp(31 to 36), s_6);
        result(25 to 28) := s_map(temp(37 to 42), s_7);
        result(29 to 32) := s_map(temp(43 to 48), s_8);

        return result;
    end function feistel;
   
    function ebs(w:w32) return w48 is
        variable result:w48;
    begin
        for i in 1 to 48 loop
            result(i) := w(e_sel_table(i));
        end loop;
        return result;
    end function;

    function s_map(a:w6; s:s_t) return w4 is
        variable row    : natural range 0 to 3;
        variable col    : natural range 0 to 15;
        variable result : std_ulogic_vector(1 to 4);
    begin
        row := to_integer(unsigned(a(1) & a(6)));
        col := to_integer(unsigned(a(2 to 5)));
        result := std_ulogic_vector(to_unsigned(s(row*4 + col)));
        return result;
    end function s_map;

end package body des_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
