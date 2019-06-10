--------------------------------------------------
--                                              --
--  Testbench for DES Cracker                   --
--  By Yohann Jacob Sandvik and Trym Sneltvedt  --
--                                              --
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.des_pkg.all;

-- test for subkey generation
-- test for e bit selection permutation function
-- test for initial permutation function
-- test for s_map function
-- test for feistel function

entity des_pkg_sim is
    --port(
    --    keys : out w768
    --);
end entity des_pkg_sim;

architecture sim of des_pkg_sim is
    -------------------
    -- Package tests --
    -------------------

    -- Initial permutation
    constant ip_test_w : w64 := 
        "0000000100100011010001010110011110001001101010111100110111101111";
    constant ip_test_res : w64 :=
        "1100110000000000110011001111111111110000101010101111000010101010";
   
    -- E bit selection
    constant ebs_test_w : w32 :=
        "11110000101010101111000010101010";
    constant ebs_test_res : w48 :=
        "011110100001010101010101011110100001010101010101";
    
    constant smap_test_a : w6 := "101010";
    -- r 10   2
    -- c 0101 5
    constant smap_test_res1 : w4 := "0110"; -- 6
    constant smap_test_res2 : w4 := "0100"; -- 4
    constant smap_test_res3 : w4 := "1111"; -- 15
    constant smap_test_res4 : w4 := "1011"; -- 11
    constant smap_test_res5 : w4 := "1101"; -- 13
    constant smap_test_res6 : w4 := "1000"; -- 8
    constant smap_test_res7 : w4 := "0011"; -- 3
    constant smap_test_res8 : w4 := "1100"; -- 12

    constant smap_test : w4 := s_map(smap_test_a, s_1); 
    
    -- Feistel function
    constant feistel_test_R : w32 := 
        "11110000101010101111000010101010";
    constant feistel_test_K : w48 := 
        "000110110000001011101111111111000111000001110010";
    constant feistel_test_res : w32 := 
        "00100011010010101010100110111011";

    -- Sub key generation -- MUST BE CHANGED FOR 56 BIT FORMAT
    -- constant skg_initial_key : w64 := 
    --     "00010011 00110100 01010111 01111001 10011011 10111100 11011111 11110001";
    constant skg_initial_key : w56 := 
        "00010010011010010101101111001001101101111011011111111000";
    constant skg_subkeys : w768 := 
        "000110110000001011101111111111000111000001110010" &
        "011110011010111011011001110110111100100111100101" &
        "010101011111110010001010010000101100111110011001" &
        "011100101010110111010110110110110011010100011101" &
        "011111001110110000000111111010110101001110101000" &
        "011000111010010100111110010100000111101100101111" &
        "111011001000010010110111111101100001100010111100" &
        "111101111000101000111010110000010011101111111011" &
        "111000001101101111101011111011011110011110000001" &
        "101100011111001101000111101110100100011001001111" &
        "001000010101111111010011110111101101001110000110" &
        "011101010111000111110101100101000110011111101001" &
        "100101111100010111010001111110101011101001000001" &
        "010111110100001110110111111100101110011100111010" &
        "101111111001000110001101001111010011111100001010" &
        "110010110011110110001011000011100001011111110101"; 

    constant iip_test_in : w64 := 
        "0000101001001100110110011001010101000011010000100011001000110100";

    constant iip_test_out : w64 := 
        "1000010111101000000100110101010000001111000010101011010000000101";

    -- sub_key_step tests
    constant init_key : w56 := x"12695BC9B7B7F8";
    constant c1d1 : w56 := x"E19955FAACCF1E"; 
    constant c1d2 : w56 := x"C332ABF5599E3D"; 
    constant c1d3 : w56 := x"0CCAAFF56678F5"; 
    constant c1d4 : w56 := x"332ABFC599E3D5"; 
    constant c1d5 : w56 := x"CCAAFF06678F55"; 
    constant c1d6 : w56 := x"32ABFC399E3D55"; 
    constant c1d7 : w56 := x"CAAFF0C678F556"; 
    constant c1d8 : w56 := x"2ABFC339E3D559"; 
    constant c1d9 : w56 := x"557F8663C7AAB3"; 
    constant c1d10 : w56 := x"55FE199F1EAACC";
    constant c1d11 : w56 := x"57F8665C7AAB33";
    constant c1d12 : w56 := x"5FE19951EAACCF";
    constant c1d13 : w56 := x"7F866557AAB33C";
    constant c1d14 : w56 := x"FE19955EAACCF1";
    constant c1d15 : w56 := x"F866557AAB33C7";
    constant c1d16 : w56 := x"F0CCAAF556678F";

    constant des_step_test_subkey : w48 := "000110110000001011101111111111000111000001110010"; -- K1
    constant des_step_test_r : w32 := "11110000101010101111000010101010"; -- R0
    constant des_step_test_l : w32 := "11001100000000001100110011111111"; -- L0
    constant des_step_test_result : w64 := "1111000010101010111100001010101011101111010010100110010101000100"; -- L1 & R1
begin
    -- Initial permutation
    assert (ip(ip_test_w) = ip_test_res) report "ERROR: Initial permutation gives bad output" severity error;
    
    -- E bit selection
    assert (ebs(ebs_test_w) = ebs_test_res) report "ERROR: E bit selection gives bad output" severity error;

    -- Sub key generation
    assert (sub_key_gen(skg_initial_key) = skg_subkeys) report "ERROR: generated keys do not match answer" severity error;
    
    -- smap test
    assert (smap_test = smap_test_res1) report "S map 1 failed " & 
        integer'image(to_integer(unsigned(smap_test))) &
        " Should be " & 
        integer'image(to_integer(unsigned(smap_test_res1)))
        severity error;
    assert (s_map(smap_test_a, s_2) = smap_test_res2) report "S map 2 failed" severity error;
    assert (s_map(smap_test_a, s_3) = smap_test_res3) report "S map 3 failed" severity error;
    assert (s_map(smap_test_a, s_4) = smap_test_res4) report "S map 4 failed" severity error;
    assert (s_map(smap_test_a, s_5) = smap_test_res5) report "S map 5 failed" severity error;
    assert (s_map(smap_test_a, s_6) = smap_test_res6) report "S map 6 failed" severity error;
    assert (s_map(smap_test_a, s_7) = smap_test_res7) report "S map 7 failed" severity error;
    assert (s_map(smap_test_a, s_8) = smap_test_res8) report "S map 8 failed" severity error;

    -- Feistel function
    assert (feistel(feistel_test_R, feistel_test_K) = feistel_test_res) report "ERROR: Feistel function gives bad output " & 
        integer'image(to_integer(unsigned(feistel(feistel_test_R, feistel_test_K)))) &
        " Should be " &
        integer'image(to_integer(unsigned(feistel_test_res))) severity error;
    
    -- Inverse initial permutation
    assert (iip(iip_test_in) = iip_test_out) report "iip test failed" severity error;  

    -- Single iteration of 16 step cracker procedure
    assert (des_step(des_step_test_subkey, des_step_test_l, des_step_test_r) = des_step_test_result) report "DES step test failed" &
    "resultat: " & integer'image(to_integer(unsigned(des_step(des_step_test_subkey, des_step_test_l, des_step_test_r)))) & 
    "fasit: " & integer'image(to_integer(unsigned(des_step_test_result))) severity error;

    -- Subkey step function
    
end architecture sim;
