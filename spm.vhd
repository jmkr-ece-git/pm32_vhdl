-- ============================================================================
-- Serial-Parallel Multiplier (SPM)
-- Converted from Verilog to VHDL
-- Based on ATML AT6000 FPGA application notes DOC0716 and DOC0529
-- Original Verilog by mshalan@aucegypt.edu, 2016
-- Conversion with detailed comments for clarity
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- =========================
-- Top-Level Entity: SPM
-- =========================
entity spm is
    generic (
        SIZE : integer := 32  -- Bit-width of multiplier input
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        y   : in  std_logic;
        x   : in  std_logic_vector(SIZE-1 downto 0);
        p   : out std_logic
    );
end entity spm;

architecture Behavioral of spm is

    -- Internal signals
    signal pp : std_logic_vector(SIZE-1 downto 1); -- Partial products
    signal xy : std_logic_vector(SIZE-1 downto 0); -- Not used in original code

begin

    -- First Carry Save Adder instance
    csa0_inst : entity work.CSADD
        port map (
            clk => clk,
            rst => rst,
            x   => x(0) and y,
            y   => pp(1),
            sum => p
        );

    -- Generate remaining Carry Save Adders
    gen_csa : for i in 1 to SIZE-2 generate
        csa_inst : entity work.CSADD
            port map (
                clk => clk,
                rst => rst,
                x   => x(i) and y,
                y   => pp(i+1),
                sum => pp(i)
            );
    end generate;

    -- Two's Complement stage
    tcmp_inst : entity work.TCMP
        port map (
            clk => clk,
            rst => rst,
            a   => x(SIZE-1) and y,
            s   => pp(SIZE-1)
        );

end architecture Behavioral;


-- ============================================================================
-- Carry Save Adder (CSADD)
-- ============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity CSADD is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        x   : in  std_logic;
        y   : in  std_logic;
        sum : out std_logic
    );
end entity CSADD;

architecture Behavioral of CSADD is
    signal sc    : std_logic := '0'; -- Carry storage
    signal hsum1, hco1, hsum2, hco2 : std_logic;
begin

    -- Half adder 1
    hsum1 <= y xor sc;
    hco1  <= y and sc;

    -- Half adder 2
    hsum2 <= x xor hsum1;
    hco2  <= x and hsum1;

    -- Sequential logic
    process(clk, rst)
    begin
        if rst = '1' then
            sum <= '0';
            sc  <= '0';
        elsif rising_edge(clk) then
            sum <= hsum2;
            sc  <= hco1 xor hco2;
        end if;
    end process;

end architecture Behavioral;

-- ============================================================================
-- Two's Complement (TCMP)
-- ============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity TCMP is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic;
        s   : out std_logic
    );
end entity TCMP;

architecture Behavioral of TCMP is
    signal z : std_logic := '0';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            s <= '0';
            z <= '0';
        elsif rising_edge(clk) then
            z <= a or z;
            s <= a xor z;
        end if;
    end process;

end architecture Behavioral;