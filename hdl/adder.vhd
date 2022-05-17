--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     adder - Behavioural
-- Project Name:    6502
-- Description:     This component describes an adder
--
-- Revision     Date       Author     Comments
-- v0.1         20220514   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity adder is
    generic (
        G_WIDTH : integer := 8
    );
    port (

        A : in STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
        B : in STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
        Cin : in STD_LOGIC;
        Z : out STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
        Cout : out STD_LOGIC
    );
end entity adder;

architecture Behavioural of adder is

    signal A_i : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal B_i : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal Cin_i : STD_LOGIC;
    signal Z_i : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);
    signal Cout_i : STD_LOGIC;
    
    signal ripple_carry : STD_LOGIC_VECTOR(G_WIDTH-1 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    A_i <= A;
    B_i <= B;
    Cin_i <= Cin;
    Z <= Z_i;
    Cout <= Cout_i;


    -------------------------------------------------------------------------------
    -- RIPPLE CARRY ADDER
    -------------------------------------------------------------------------------
    Z_i(0) <= A_i(0) XOR B_i(0) XOR Cin_i;
    ripple_carry(0) <= (A_i(0) AND B_i(0)) OR ( Cin_i AND (A_i(0) XOR B_i(0)));

    GEN_REG: for I in 1 to G_WIDTH-1 generate
        Z_i(I) <= A_i(I) XOR B_i(I) XOR ripple_carry(I-1);
        ripple_carry(I) <= (A_i(I) AND B_i(I)) OR ( ripple_carry(I-1) AND (A_i(I) XOR B_i(I)));
    end generate GEN_REG;

    Cout_i <= ripple_carry(ripple_carry'high);
   

end Behavioural;
