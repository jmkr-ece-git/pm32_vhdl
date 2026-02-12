-- ============================================================================
-- Signed 32x32 Multiplier using Serial-Parallel Multiplier (SPM)
-- Converted from Verilog to VHDL
-- Original Verilog by mshalan@aucegypt.edu, 2016
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pm32 is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        mc    : in  std_logic_vector(31 downto 0); -- Multiplicand
        mp    : in  std_logic_vector(31 downto 0); -- Multiplier
        p     : out std_logic_vector(63 downto 0); -- Product
        done  : out std_logic
    );
end entity pm32;

architecture Behavioral of pm32 is

    -- Internal signals
    signal p_reg   : std_logic_vector(63 downto 0) := (others => '0');
    signal pw      : std_logic; -- Partial product bit from SPM
    signal Y       : std_logic_vector(31 downto 0) := (others => '0');
    signal cnt     : unsigned(7 downto 0) := (others => '0');
    signal ncnt    : unsigned(7 downto 0) := (others => '0');
    signal state   : unsigned(1 downto 0) := (others => '0');
    signal nstate  : unsigned(1 downto 0) := (others => '0');

    -- State encoding
    constant IDLE    : unsigned(1 downto 0) := "00";
    constant RUNNING : unsigned(1 downto 0) := "01";
    constant DONEE    : unsigned(1 downto 0) := "10";

    -- Control signal for SPM
    signal y_sig : std_logic;

begin

    -------------------------------------------------------------------------
    -- State Register
    -------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= nstate;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- State Transition Logic
    -------------------------------------------------------------------------
    process(state, start, cnt)
    begin
        nstate <= state;
        case state is
            when IDLE =>
                if start = '1' then
                    nstate <= RUNNING;
                end if;

            when RUNNING =>
                if cnt = 32 then
                    nstate <= DONEE;
                end if;

            when DONEE =>
                nstate <= IDLE;

            when others =>
                nstate <= IDLE;
        end case;
    end process;

    -------------------------------------------------------------------------
    -- Counter Logic
    -------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            cnt <= (others => '0');
        elsif rising_edge(clk) then
            if state = RUNNING then
                cnt <= cnt + 1;
            else
                cnt <= (others => '0');
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Product Register Shift
    -------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            p_reg <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' then
                p_reg <= (others => '0');
                Y <= mp; -- Load multiplier into Y
            elsif state = RUNNING then
                p_reg <= pw & p_reg(63 downto 1); -- Shift right, insert pw
                Y <= '0' & Y(31 downto 1); -- Shift multiplier bits
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- SPM Instance
    -------------------------------------------------------------------------
    y_sig <= Y(0) when state = RUNNING else '0';

    spm32_inst : entity work.spm
        generic map (
            SIZE => 32
        )
        port map (
            clk => clk,
            rst => rst,
            x   => mc,
            y   => y_sig,
            p   => pw
        );

    -------------------------------------------------------------------------
    -- Outputs
    -------------------------------------------------------------------------
    p    <= p_reg;
    done <= '1' when state = DONEE else '0';

end architecture Behavioral;
