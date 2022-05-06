--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     processor - Behavioural
-- Project Name:    6502
-- Description:     This component describes the top level processor
--
-- Revision     Date       Author     Comments
-- v0.1         20220505   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity processor is
    port (
        sys_reset_n : in STD_LOGIC;
        clock : in STD_LOGIC;
        address : out STD_LOGIC_VECTOR(15 downto 0);
        data : in STD_LOGIC_VECTOR(7 downto 0)
    );
end entity processor;

architecture Behavioural of processor is

    component pc is
        port(
            sys_reset_n : in STD_LOGIC;
            clock : in STD_LOGIC;
            inc : in STD_LOGIC;
            Z : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component decoder is
        port (
            sys_reset_n : in STD_LOGIC;
            clock : in STD_LOGIC;
            A : in STD_LOGIC_VECTOR(7 downto 0);
            control_signals : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal address_i : STD_LOGIC_VECTOR(15 downto 0);
    signal data_i : STD_LOGIC_VECTOR(7 downto 0);

    -- CONTROL PATH
    signal cp_pc_inc : STD_LOGIC;
    signal cp_regA_ld : STD_LOGIC;
    signal cp_regABL_ld : STD_LOGIC;
    signal cp_regABH_ld : STD_LOGIC;
    signal cp_regABH_clr : STD_LOGIC;
    
    
    
    
    -- PROGRAM COUNTER
    signal program_counter_i : STD_LOGIC_VECTOR(15 downto 0);
    
    -- DECODER
    signal from_memory : STD_LOGIC_VECTOR(7 downto 0);
    signal control_signals : STD_LOGIC_VECTOR(31 downto 0);
    
    -- REGISTERS
    signal regA : STD_LOGIC_VECTOR(7 downto 0);
    signal regABH : STD_LOGIC_VECTOR(7 downto 0);
    signal regABL : STD_LOGIC_VECTOR(7 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    from_memory <= data;
    
    address <= program_counter_i;

    -------------------------------------------------------------------------------
    -- PROGRAM COUNTER
    -------------------------------------------------------------------------------
    pc_inst00: component pc port map( sys_reset_n => sys_reset_n_i, clock => clock_i,
                                      inc => cp_pc_inc, Z => program_counter_i);


    -------------------------------------------------------------------------------
    -- DECODER
    -------------------------------------------------------------------------------
    decoder_inst00: component decoder port map( sys_reset_n => sys_reset_n_i, clock => clock_i, A => from_memory, control_signals => control_signals);
    
    cp_pc_inc <= control_signals(0);
    cp_regA_ld <= control_signals(1);

    cp_regABL_ld <= control_signals(2);
    cp_regABH_ld <= control_signals(3);
    cp_regABH_clr <= control_signals(4);

    -------------------------------------------------------------------------------
    -- REGISTERS
    -------------------------------------------------------------------------------
    PREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            regA <= x"00";
            regABL <= x"00";
            regABH <= x"00";
        elsif rising_edge(clock_i) then 
            if cp_regA_ld = '1' then 
                regA <= from_memory;
            end if;

            if cp_regABH_clr = '1' then 
                regABH <= x"00";
            elsif cp_regABH_ld = '1' then 
                regABH <= from_memory;
            end if;

            if cp_regABL_ld = '1' then 
                regABL <= from_memory;
            end if;

        end if;
    end process;

        

end Behavioural;
