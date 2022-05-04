--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     pc - Behavioural
-- Project Name:    6502
-- Description:     This component describes the accumulator
--
-- Revision     Date       Author     Comments
-- v0.1         20220504   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity accumulator is
    port (
        sys_reset_n : in STD_LOGIC;
        clock : in STD_LOGIC;
        load : in STD_LOGIC;
        A : in STD_LOGIC_VECTOR(7 downto 0);
        Z : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity accumulator;

architecture Behavioural of accumulator is

    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal load_i : STD_LOGIC;
    signal A_i : STD_LOGIC_VECTOR(7 downto 0);
    signal Z_i : STD_LOGIC_VECTOR(7 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    load_i <= load;
    A_i <= A;
    Z <= Z_i;

    -------------------------------------------------------------------------------
    -- REGISTER
    -------------------------------------------------------------------------------
    PREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            Z_i <= x"00";
        elsif rising_edge(clock_i) then 
            if load_i = '1' then 
                Z_i <= A_i;
            end if;
        end if;
    end process;
   

end Behavioural;
