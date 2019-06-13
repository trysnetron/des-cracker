------------------------------------------------
-----------------DES cracker--------------------
---by Trym Sneltvedt and Yohann Jacob Sandvik---
------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Setting up entity of the des_cracker --  
entity des_cracker is
port(
    aclk           : in  std_ulogic;                     -- master clock
    aresetn        : in  std_ulogic;                     -- synchronous active low reset

    -- Read address channel signals
    s0_axi_araddr  : in  std_ulogic_vector(11 downto 0); -- read address
    s0_axi_arvalid : in  std_ulogic;                     -- read address valid
    s0_axi_arready : out std_ulogic;                     -- read address acknowledge
  -- arprot

    -- Write address channel signals
    s0_axi_awaddr  : in  std_ulogic_vector(11 downto 0); -- write address
    s0_axi_awvalid : in  std_ulogic;                     -- write address valid flag
    s0_axi_awready : out std_ulogic;                     -- write address acknowledge
  -- awprot

    -- Write data channel signals
    s0_axi_wdata   : in  std_ulogic_vector(31 downto 0); -- write data
    s0_axi_wstrb   : in  std_ulogic_vector(3 downto 0);  -- write byte enables
    s0_axi_wvalid  : in  std_ulogic;                     -- write data and byte enables valid
    s0_axi_wready  : out std_ulogic;                     -- write data and byte enables acknowledge

    -- Read data channel signals
    s0_axi_rdata   : out std_ulogic_vector(31 downto 0); -- read data response to CPU
    s0_axi_rresp   : out std_ulogic_vector(1 downto 0);  -- read status response (OKAY, EXOKAY, SLVERR or DECERR)
    s0_axi_rvalid  : out std_ulogic;                     -- read data and status response valid flag
    s0_axi_rready  : in  std_ulogic;                     -- read response acknowledge

    -- Write response channel signals
    s0_axi_bresp   : out std_ulogic_vector(1 downto 0);  -- write status response (OKAY, EXOKAY, SLVERR or DECERR)
    s0_axi_bvalid  : out std_ulogic;                     -- write status response valid
    s0_axi_bready  : in  std_ulogic;                     -- write response acknowledge

    irq            : out std_ulogic;                     -- interrupt request
    led            : out std_ulogic_vector(3 downto 0)   -- wired to the four user LEDs 
);
end entity des_cracker;

-- Setting up architecture of the des_cracker
architecture rtl of des_cracker is
    constant axi_resp_OKAY		: std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_EXOKAY	: std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_SLVERR	: std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_DECERR    : std_ulogic_vector(1 downto 0) := "11";
    
    signal p              : std_ulogic_vector(63 downto 0) := (others => '0'); -- The plaintext           base adress: 0x000
    signal c              : std_ulogic_vector(63 downto 0) := (others => '0'); -- The ciphertext          base adress: 0x008
    signal k0             : std_ulogic_vector(55 downto 0) := (others => '0'); -- The starting secret key base adress: 0x010
    signal k              : std_ulogic_vector(55 downto 0) := (others => '0'); -- The current secret key  base adress: 0x018
    signal k1             : std_ulogic_vector(55 downto 0) := (others => '0'); -- The found secret key    base adress: 0x020
    signal k_local        : std_ulogic_vector(55 downto 0) := (others => '0'); -- The current secret key 
    
    signal crack_run      : std_ulogic := '0'; -- Command to make engines begin checking keys
    signal crack_complete : std_ulogic := '0'; -- Flag for engines let us know that correct key has been found
    signal k_freeze       : std_ulogic := '0'; -- Flag to indicate that CPU is reading current key 'k'

    type rw_states is (IDLE, WAITING);
    signal state_r, state_w : rw_states;

begin 
    sm: entity work.sm(rtl)
    generic map(
        nr_engines => 8
    )
    port map(
        clk     => aclk,    
        sresetn => aresetn,
        run     => crack_run,
        p       => p,
        c       => c,
        k0      => k0,
        k       => k_local,
        k1      => k1,
        irq     => crack_complete
    );
  
    -- Shorthands
    led           <= k(33 downto 30);
    irq           <= crack_complete;
    
    -- Processes
    update_current_key: process(aclk)
    begin
        if rising_edge(aclk) then
            if k_freeze = '0' then
                k <= k_local;
            end if;
        end if;
    end process update_current_key;

-- Read process.
axi_read: process(aclk) begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            s0_axi_arready <= '0';
            s0_axi_rdata   <= (others => '0');
            s0_axi_rresp   <= axi_resp_OKAY;
            state_r        <= IDLE;	
        else
            case state_r is
                when idle =>
                    if s0_axi_arvalid = '1' then 
                        s0_axi_arready <= '1';
                        s0_axi_rvalid  <= '1';
                        s0_axi_rresp   <= axi_resp_OKAY; 
                        state_r        <= WAITING;
            
                        -- LSB's of p (plain text)
                        if unsigned(s0_axi_araddr) < x"004" then
                            -- Unsure what is MSB and LSB
                            s0_axi_rdata <= p(31 downto 0);
                        
                        -- MSB's of p (plain text)
                        elsif unsigned(s0_axi_araddr) < x"008" then 
                            s0_axi_rdata <= p(63 downto 32);
                        
                        -- LSB's of c (cipher text)
                        elsif unsigned(s0_axi_araddr) < x"00c" then 
                            s0_axi_rdata <= c(31 downto 0);
                        
                        -- MSB's of c (cipher text)
                        elsif unsigned(s0_axi_araddr) < x"010" then 
                            s0_axi_rdata <= c(63 downto 32);
                        
                        -- LSB's of k0 (starting key)
                        elsif unsigned(s0_axi_araddr) < x"014" then 
                            s0_axi_rdata <= k0(31 downto 0);
                        
                        -- MSB's of k0 (starting key)
                        elsif unsigned(s0_axi_araddr) < x"018" then
                            s0_axi_rdata <= x"00" & k0(55 downto 32);
                        
                        -- LSB's of k (current key)
                        elsif unsigned(s0_axi_araddr) < x"01c" then 
                            s0_axi_rdata <= k(31 downto 0);
                            k_freeze <= '1'; -- k needs to be frozen
                        
                        -- MSB's of k (current key)
                        elsif unsigned(s0_axi_araddr) < x"020" then 
                            s0_axi_rdata <= x"00" & k(55 downto 32);
                            k_freeze <= '0'; -- k needs to be unfrozen
                        
                        -- LSB's of k1 (found key)
                        elsif unsigned(s0_axi_araddr) < x"024" then 
                            s0_axi_rdata <= k1(31 downto 0);
                        
                        -- MSB's of k1 (found key)
                        elsif unsigned(s0_axi_araddr) < x"028" then 
                            s0_axi_rdata <= x"00" & k1(55 downto 32);
                        
                        else
                            s0_axi_rresp  <= axi_resp_DECERR;
                        end if;
                    end if;
                when waiting =>
                    if s0_axi_rready = '1' then
                        s0_axi_rvalid <= '0'; -- Handshake finished, read data no longer valid
                        state_r <= idle;
                    end if;
            end case;
        end if;
    end if;
end process;

-- Write process
axi_write: process(aclk) 
begin
    if rising_edge(aclk) then
        s0_axi_awready <= '0';
        s0_axi_wready  <= '0';
        
        if aresetn = '0' then
            s0_axi_wready <= '0';
            s0_axi_bresp  <= (others => '0');
            p             <= (others => '0');
            c             <= (others => '0');
            k0            <= (others => '0');
            crack_run     <= '0';
            state_w       <= IDLE;
        else
            case state_w is
                when IDLE =>
                    if s0_axi_awvalid = '1' and s0_axi_wvalid = '1' then
                        s0_axi_awready <= '1';
                        s0_axi_wready  <= '1';
                        s0_axi_bvalid  <= '1';
                        s0_axi_bresp   <= axi_resp_OKAY;
                        state_w <= waiting;

                        -- LSB's of p (plain text)
                        if unsigned(s0_axi_awaddr) < x"004" then
                            p(31 downto 0) <= s0_axi_wdata;

                        -- MSB's of p (plain text)
                        elsif unsigned(s0_axi_awaddr) < x"008" then 
                            p(63 downto 32) <= s0_axi_wdata;
                
                        -- LSB's of c (cipher text)
                        elsif unsigned(s0_axi_awaddr) < x"00c" then 
                            c(31 downto 0) <= s0_axi_wdata;

                        -- MSB's of c (cipher text)
                        elsif unsigned(s0_axi_awaddr) < x"010" then 
                            c(63 downto 32) <= s0_axi_wdata;

                        -- LSB's of k0 (starting key)
                        elsif unsigned(s0_axi_awaddr) < x"014" then 
                            -- Stop cracking machine
                            crack_run <= '0';
                            k0(31 downto 0) <= s0_axi_wdata;

                        -- MSB's of k0 (starting key)
                        elsif unsigned(s0_axi_awaddr) < x"018" then 
                            -- start cracking machine
                            crack_run <= '1';
                            k0(55 downto 32) <= s0_axi_wdata(23 downto 0); -- Ignore MSB
                        -- MSB's of k1 (found key)
                        elsif unsigned(s0_axi_awaddr) < x"028" then 
                            s0_axi_bresp  <= axi_resp_SLVERR; -- Registers k and k1 are read-only
                        else
                            s0_axi_bresp  <= axi_resp_DECERR;
                        end if;
                    end if;
                when waiting =>
                    if s0_axi_bready = '1' then
                        s0_axi_bvalid <= '0';
                        state_w <= idle;
                    end if;
            end case;
        end if;
    end if;
end process;

end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
