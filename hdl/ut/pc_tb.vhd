--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     pc_b - Behavioural
-- Project Name:    6502
-- Description:     Unit test for the program counter
--
-- Revision     Date       Author     Comments
-- v0.1         20220504   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity pc_tb is
end entity pc_tb;

architecture Behavioural of pc_tb is

    component pc is
        port(
            sys_reset_n : in STD_LOGIC;
            clock : in STD_LOGIC;
            inc : in STD_LOGIC;
            Z : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal sys_reset_n : STD_LOGIC;
    signal clock : STD_LOGIC;
    signal inc : STD_LOGIC;
    signal Z : STD_LOGIC_VECTOR(15 downto 0);

    constant clock_period : time := 10 ns;

begin

    -------------------------------------------------------------------------------
    -- STIMULI
    -------------------------------------------------------------------------------
    PSTIM: process
    begin
        sys_reset_n <= '0';
        inc <= '0';
        wait for clock_period * 10;

        sys_reset_n <= '1';
        wait for clock_period * 10;

        assert (Z = x"0000") report "Reset not working" severity error;
        
        inc <= '1';
        wait for clock_period;
        inc <= '0';
        assert (Z = x"0001") report "Inc not working" severity error;

        sys_reset_n <= '0';
        wait for clock_period;
        sys_reset_n <= '1';
        assert (Z = x"0000") report "Reset not working" severity error;

        inc <= '1';
        wait for clock_period * 16;
        assert (Z = x"0010") report "Inc not working" severity error;

        wait for clock_period * (256-16);
        assert (Z = x"0100") report "Inc not working" severity error;

        wait for clock_period * (4096-256);
        assert (Z = x"1000") report "Inc not working" severity error;

        wait for clock_period * (65535-4096);
        assert (Z = x"FFFF") report "Inc not working" severity error;
        
        wait for clock_period;
        assert (Z = x"0000") report "Overflow not working" severity error;

        inc <= '0';
        report "basic counting test: OK";

        wait;
    end process;

    -------------------------------------------------------------------------------
    -- DUT
    -------------------------------------------------------------------------------
    DUT: component pc port map(
        sys_reset_n => sys_reset_n,
        clock => clock,
        inc => inc,
        Z => Z
    );


    -------------------------------------------------------------------------------
    -- CLOCK
    -------------------------------------------------------------------------------
    PCLK: process
    begin
        clock <= '1';
        wait for clock_period/2;
        clock <= '0';
        wait for clock_period/2;
    end process PCLK;

end Behavioural;
