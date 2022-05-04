--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     ALU - Behavioural
-- Project Name:    6502
-- Description:     This component describes the ALU
--
-- Revision     Date       Author     Comments
-- v0.1         20220504   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity ALU is
    port (
        A : in STD_LOGIC_VECTOR(7 downto 0);
        Z : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity ALU;

architecture Behavioural of ALU is


begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------


    -------------------------------------------------------------------------------
    -- NODE
    -------------------------------------------------------------------------------
    

end Behavioural;
