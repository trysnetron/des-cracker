library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.des_pkg.all;

entity des_cracker_small is
	port(
		aclk		: in 	std_ulogic;	-- Master clock.
		aresetn		: in 	std_ulogic;	-- Sync. AXI. Reset.
		p		    : in 	w64;		-- Plaintext.
		c		    : in 	w64;		-- Ciphertext.
		k0		    : in	w56;		-- Starting key.
		start_crack	: in	std_ulogic;	-- Start state machine.
		k		    : out	w56;		-- Current key.
		irq		    : out	std_ulogic 	-- Cracking complete flag.
	);
end entity des_cracker_small;

architecture rtl of des_cracker_small is
-- Signals

	type state_type is (idle, encrypt, encrypt_init, compare); -- State types.
	signal cur_state: state_type; -- Current state.

	-- Key with inserted place holder parity bits.
	signal k64	: w64;

	-- Registers for intermediate computation results.
	signal p_right		: w32;
	signal p_left		: w32;
	signal p_right_new	: w32;
	signal p_left_new	: w32;
	signal p_perm		: w64;
	signal p_perm_left	: w32;
	signal p_perm_right	: w32;
	signal k_56		    : w56;
	signal k_left		: w28;
	signal k_right		: w28;
	signal k_sub		: w48;

	signal k_local		: w56;
	signal c_computed	: w64;
	signal irq_local	: std_ulogic;

	signal counter 	: natural range 1 to 17;

begin
-- Modules.
 -- no modules yet.


-- Cracker SVM
process(aclk) begin
	if rising_edge(aclk) then	
		if aresetn = '0' then -- Reset.

			-- Internal signals.
			counter 	<= 1;
			cur_state 	<= idle;
			-- Output signals.
			k 		    <= k0;
			irq_local	<= '0';

		else
			if irq_local = '1' then
				irq_local <= '0';
			end if;
			-- Do SVM stuff.
			case cur_state is
				when idle =>
					if start_crack = '1' then
						cur_state <= encrypt_init;
						k_local 	<= k0; -- Assign starting key.
					end if;
					-- Else do nothing. Idle.

				when encrypt_init =>
						-- Prepare for feistel rounds.
						p_left_new 	<= p_perm( 1 to 32);
						p_right_new <= p_perm(33 to 64);

						-- Prepare key Feistel round.
						k_left 	<= left_shift(k_56(1 to 28), shift_table(counter));
						k_right <= left_shift(k_56(29 to 56), shift_table(counter));
						cur_state <= encrypt;

				when encrypt =>

					if counter = 17 then
						-- Feistel rounds complete.
						c_computed <= fp(p_right & p_left);
						counter <= 1;
						k <= k_local;
						cur_state <= compare;

					elsif counter = 16 then
						-- Final Feistel round.			
						p_left_new <= p_right;
						p_right_new <= feistel(p_right, k_sub) xor p_left;
						counter <= counter + 1;

					else
						-- Feistel round.			
						p_left_new <= p_right;
						p_right_new <= feistel(p_right, k_sub) xor p_left;

						-- Key schedule.
						k_left <= left_shift(k_left, shift_table(counter + 1));
						k_right <= left_shift(k_right, shift_table(counter + 1));

						counter <= counter + 1;

					end if;

				when compare =>
					if c = c_computed then
						-- Right key found.
						irq_local <= '1';
						cur_state <= idle;
					else
						-- Go to next key and encrypt again.
						k_local <= w56(unsigned(k_local) + 1);
						cur_state <= encrypt_init;
						
					end if;
			end case;
		end if;
	end if;
end process;

-- Insert parity placeholder bits.
k64 <= 	k_local( 1 to  7) & "0" & k_local( 8 to 14) & "0" & k_local(15 to 21)
		& "0" & k_local(22 to 28) & "0" & k_local(29 to 35) & "0" & 
		k_local(36 to 42) & "0" & k_local(43 to 49) & "0" & k_local(50 to 56)
		& "0";
p_left 	<= p_left_new;
p_right <= p_right_new;
k_sub 	<= pc2(k_left & k_right);
p_perm 	<= ip(p); -- Initial permutation.
k_56 	<= pc1(k64);


irq <= irq_local;


end architecture;
