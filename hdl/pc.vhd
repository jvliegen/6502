--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     pc - Behavioural
-- Project Name:    6502
-- Description:     This component describes the program counter
--
-- Revision     Date       Author     Comments
-- v0.1         20220504   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity pc is
    port (
        sys_reset_n : in STD_LOGIC;
        clock : in STD_LOGIC;
        inc : in STD_LOGIC;
        Z : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity pc;

architecture Behavioural of pc is

    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal inc_i : STD_LOGIC;
    signal program_counter, program_counter_incremented, ripple_carry : STD_LOGIC_VECTOR(15 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    inc_i <= inc;
    Z <= program_counter;

    -------------------------------------------------------------------------------
    -- REGISTER
    -------------------------------------------------------------------------------
    PREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            program_counter <= x"0000";
        elsif rising_edge(clock_i) then 
            if inc_i = '1' then 
                program_counter <= program_counter_incremented;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------------
    -- ADDER
    -------------------------------------------------------------------------------
    program_counter_incremented(0) <= not(program_counter(0));                      ripple_carry(1) <= program_counter(0);
    program_counter_incremented(1) <= program_counter(1) XOR ripple_carry(1);       ripple_carry(2) <= program_counter(1) AND ripple_carry(1);
    program_counter_incremented(2) <= program_counter(2) XOR ripple_carry(2);       ripple_carry(3) <= program_counter(2) AND ripple_carry(2);
    program_counter_incremented(3) <= program_counter(3) XOR ripple_carry(3);       ripple_carry(4) <= program_counter(3) AND ripple_carry(3);
    program_counter_incremented(4) <= program_counter(4) XOR ripple_carry(4);       ripple_carry(5) <= program_counter(4) AND ripple_carry(4);
    program_counter_incremented(5) <= program_counter(5) XOR ripple_carry(5);       ripple_carry(6) <= program_counter(5) AND ripple_carry(5);
    program_counter_incremented(6) <= program_counter(6) XOR ripple_carry(6);       ripple_carry(7) <= program_counter(6) AND ripple_carry(6);
    program_counter_incremented(7) <= program_counter(7) XOR ripple_carry(7);       ripple_carry(8) <= program_counter(7) AND ripple_carry(7);
    program_counter_incremented(8) <= program_counter(8) XOR ripple_carry(8);       ripple_carry(9) <= program_counter(8) AND ripple_carry(8);
    program_counter_incremented(9) <= program_counter(9) XOR ripple_carry(9);       ripple_carry(10) <= program_counter(9) AND ripple_carry(9);
    program_counter_incremented(10) <= program_counter(10) XOR ripple_carry(10);    ripple_carry(11) <= program_counter(10) AND ripple_carry(10);
    program_counter_incremented(11) <= program_counter(11) XOR ripple_carry(11);    ripple_carry(12) <= program_counter(11) AND ripple_carry(11);
    program_counter_incremented(12) <= program_counter(12) XOR ripple_carry(12);    ripple_carry(13) <= program_counter(12) AND ripple_carry(12);
    program_counter_incremented(13) <= program_counter(13) XOR ripple_carry(13);    ripple_carry(14) <= program_counter(13) AND ripple_carry(13);
    program_counter_incremented(14) <= program_counter(14) XOR ripple_carry(14);    ripple_carry(15) <= program_counter(14) AND ripple_carry(14);
    program_counter_incremented(15) <= program_counter(15) XOR ripple_carry(15);

    

end Behavioural;
