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

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal address_i : STD_LOGIC_VECTOR(15 downto 0);
    signal data_i : STD_LOGIC_VECTOR(7 downto 0);

    -- CONTROL PATH
    signal cp_pc_inc : STD_LOGIC;
    
    
    
    signal from_memory : STD_LOGIC_VECTOR(7 downto 0);

    -- PROGRAM COUNTER
    signal program_counter_i : STD_LOGIC_VECTOR(15 downto 0);


begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    address <= program_counter_i;
    from_memory <= data;

    -------------------------------------------------------------------------------
    -- CONTROL PATH
    -------------------------------------------------------------------------------  
    cp_pc_inc <= '1';

    -------------------------------------------------------------------------------
    -- PROGRAM COUNTER
    -------------------------------------------------------------------------------
    pc_inst00: component pc port map( sys_reset_n => sys_reset_n_i, clock => clock_i,
                                      inc => cp_pc_inc, Z => program_counter_i);



end Behavioural;
