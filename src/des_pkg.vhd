library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package des_pkg is
    subtype w4 is std_ulogic_vector(1 to 4);
    subtype w6 is std_ulogic_vector(1 to 6);
	subtype w12 is std_ulogic_vector(1 to 12);
    subtype w28 is std_ulogic_vector(1 to 28);
    subtype w32 is std_ulogic_vector(1 to 32);
    subtype w48 is std_ulogic_vector(1 to 48);
    subtype w56 is std_ulogic_vector(1 to 56);
    subtype w64 is std_ulogic_vector(1 to 64);
    subtype w768 is std_ulogic_vector(1 to 768);

    type ip_t  is array(1 to 64) of natural range 1 to 64;
    type pc1_t is array(1 to 56) of natural range 1 to 56;
    type pc2_t is array(1 to 48) of natural range 1 to 56;
    type es_t  is array(1 to 48) of natural range 1 to 32;
    type s_t   is array(0 to 63) of natural range 0 to 15;
	type pf_t  is array(1 to 32) of natural range 1 to 32;

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

    -- constant pc1_table : pc1_t := (
    --     57, 49, 41, 33, 25, 17, 9,
    --      1, 58, 50, 42, 34, 26, 18,
    --     10,  2, 59, 51, 43, 35, 27,
    --     19, 11,  3, 60, 52, 44, 36,
    --     63, 55, 47, 39, 31, 23, 15,
    --      7, 62, 54, 46, 38, 30, 22,
    --     14,  6, 61, 53, 45, 37, 29,
    --     21, 13,  5, 28, 20, 12,  4
    -- );
    -- ORIGINAL INDEXING IN pc1_table
    --  1  2  3  4  5  6  7  9 10 11 12 13 14 15 17 18 19 20 21 22 23 25 26 27 28 29 30 31
    -- 33 34 35 36 37 38 39 41 42 43 44 45 46 47 49 50 51 52 53 54 55 57 58 59 60 61 62 63

    -- NEW INDEXING IN pc1_table
    --  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
    -- 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56

    constant pc1_table : pc1_t := (
        50, 43, 36, 29, 22, 15, 8,
         1, 51, 44, 37, 30, 23, 16,
         9,  2, 52, 45, 38, 31, 24,
        17, 10,  3, 53, 46, 39, 32,
        56, 49, 42, 35, 28, 21, 14,
         7, 55, 48, 41, 34, 27, 20,
         13,  6, 54, 47, 40, 33, 26,
         19, 12,  5, 25, 18, 11,  4
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

	constant pf_table : pf_t := (
		16,  7, 20, 21,  
        29, 12, 28, 17,
		 1, 15, 23, 26,
		 5, 18, 31, 10,
		 2,  8, 24, 14,
		32, 27,  3,  9,
		19, 13, 30,  6,
		22, 11,  4, 25
	);

	constant iip_table : ip_t := (
		40,  8, 48, 16, 56, 24, 64, 32,
		39,  7, 47, 15, 55, 23, 63, 31,
		38,  6, 46, 14, 54, 22, 62, 30,
        37,  5, 45, 13, 53, 21, 61, 29,
        36,  4, 44, 12, 52, 20, 60, 28,
	    35,  3, 43, 11, 51, 19, 59, 27,
        34,  2, 42, 10, 50, 18, 58, 26,
        33,  1, 41,  9, 49, 17, 57, 25
	);
    
    function left_shift(w:w28; amount:natural) return w28;
    function right_shift(w:w28; amount:natural) return w28;
    function sub_key_gen(key:w56) return w768;
    function sub_key_step(key:w56; round_nr:positive) return w56;
    function feistel(R:w32; K:w48) return w32;
    function s_map(a:w6; s:s_t) return w4;
    function ip(w:w64) return w64;
    function ebs(w:w32) return w48;
	function iip(w:w64) return w64;
    function pc2(w:w56) return w48;
    function des_step(subkey:w48; left:w32; right:w32) return w64;
	function increment_key(key:w56; N:natural) return w56;

end package des_pkg;

package body des_pkg is

    -- function for incrementing key -----------------------------------------------------------------------------------------------
	function increment_key(key:w56; N:natural) return w56 is 
		variable result : unsigned(1 to 56);
	begin
		result := unsigned(key) + N;
		return std_ulogic_vector(result);
	end function increment_key;

    -- function for generating subkeys from initial key ----------------------------------------------------------------------------
    function sub_key_gen(key:w56) return w768 is -- Returns all subkeys concatenated to one long bit vector of length 728
        variable permuted_key:w56;
        variable c:w28;
        variable d:w28;
        variable concatenated_pair:w56;
        variable result:w768;
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
    end function sub_key_gen;

    -- Function for generating arbitrary subkey (NOT PERMUTED WITH PC2)
    function sub_key_step(key: w56; round_nr: positive) return w56 is
        variable c: w28;
        variable d: w28;
        variable permuted_key : w56;
    begin
        if round_nr = 1 or round_nr = 2 or round_nr = 9 or round_nr = 16 then
            if round_nr = 1 then
                for i in 1 to 56 loop
                    permuted_key(i) := key(pc1_table(i));
                end loop;
                c := permuted_key(1 to 28);
                d := permuted_key(29 to 56);
            else
                c := key(1 to 28);
                d := key(29 to 56);
            end if;
            c := left_shift(c, 1);
            d := left_shift(d, 1);
        else 
            c := left_shift(c, 2);
            d := left_shift(d, 2);
        end if;
        return c & d;
    end function sub_key_step;

    -- function for cyclic left shift -----------------------------------------------------------------------------------------------
    function left_shift(w:w28; amount:natural) return w28 is
        begin
        if amount = 2 then
            return w(3 to 28) & w(1 to 2);
        elsif amount = 1 then
            return w(2 to 28) & w(1);
        else
            assert false report "ERROR" severity failure;
        end if;
    end function left_shift;

    -- function for cyclic right shift -----------------------------------------------------------------------------------------------
    function right_shift(w:w28; amount:natural) return w28 is
        begin
        if amount = 2 then
            return w(27 to 28) & w(1 to 26);
        elsif amount = 1 then
            return w(28) & w(1 to 27);
        else
            assert false report "ERROR" severity failure;
        end if;
    end function right_shift;

    -- function for initial permutation ----------------------------------------------------------------------------------------------
    function ip(w:w64) return w64 is
        variable result:w64;
    begin
        for i in 1 to 64 loop
            result(i) := w(ip_table(i));
        end loop;
        return result;
    end function ip;

    -- e bit selection table function ------------------------------------------------------------------------------------------------
    function ebs(w:w32) return w48 is
        variable result:w48;
    begin
        for i in 1 to 48 loop
            result(i) := w(e_sel_table(i));
        end loop;
        return result;
    end function ebs;
    
    -- pc2 permutation function
    function pc2(w:w56) return w48 is
        variable result : w48;
    begin
        for i in 1 to 48 loop
            result(i) := w(pc2_table(i));
        end loop;
        return result;
    end function pc2;

    -- function to perform s-mapping according to the 8 different s-tables -----------------------------------------------------------
    function s_map(a:w6; s:s_t) return w4 is
        variable row    : natural range 0 to 3;
        variable col    : natural range 0 to 15;
        variable result : std_ulogic_vector(1 to 4);
    begin
        row := to_integer(unsigned(std_ulogic_vector'(a(1) & a(6))));
        col := to_integer(unsigned(a(2 to 5)));
        result := std_ulogic_vector(to_unsigned(s(row*16 + col), 4));
        return result;
    end function s_map;

    -- feistel function ---------------------------------------------------------------------------------------------------------------
    function feistel(R:w32; K:w48) return w32 is
        variable temp_xor:w48;
        variable temp_smap:w32;
		variable result:w32;
    begin
		-- performing bitwise xor of E(R) and subkey K_i
        temp_xor := ebs(R) xor K;
		
		-- performing s mapping of output of xor
        temp_smap( 1 to  4) := s_map(temp_xor( 1 to  6), s_1);
        temp_smap( 5 to  8) := s_map(temp_xor( 7 to 12), s_2);
        temp_smap( 9 to 12) := s_map(temp_xor(13 to 18), s_3);
        temp_smap(13 to 16) := s_map(temp_xor(19 to 24), s_4);
        temp_smap(17 to 20) := s_map(temp_xor(25 to 30), s_5);
        temp_smap(21 to 24) := s_map(temp_xor(31 to 36), s_6);
        temp_smap(25 to 28) := s_map(temp_xor(37 to 42), s_7);
        temp_smap(29 to 32) := s_map(temp_xor(43 to 48), s_8);
		
		-- performing permutation of output of s mapping
		for i in 1 to 32 loop
			result(i) := temp_smap(pf_table(i));
		end loop;
        return result;
    end function feistel;
	
	-- function to do inverse initial permutation --------------------------------------------------------------------------------------
	function iip(w:w64) return w64 is
        variable result:w64;
    begin
        for i in 1 to 64 loop
            result(i) := w(iip_table(i));
        end loop;
        return result;
	end function iip;

	-- function to do one iteration of 16 step procedure -------------------------------------------------------------------------------
	function des_step(subkey:w48; left:w32; right:w32) return w64 is
	begin
		return right & (left xor feistel(right, subkey));
	end function des_step;

end package body des_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
