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
    
    
    -- STACK POINTER
    signal stack_pointer : STD_LOGIC_VECTOR(7 downto 0);
    
    -- PROGRAM COUNTER
    signal program_counter_i : STD_LOGIC_VECTOR(15 downto 0);
    
    -- DECODER
    signal from_memory : STD_LOGIC_VECTOR(7 downto 0);
    signal control_signals : STD_LOGIC_VECTOR(31 downto 0);
    
    -- REGISTERS
    signal regA : STD_LOGIC_VECTOR(7 downto 0);
    signal regABH : STD_LOGIC_VECTOR(7 downto 0);
    signal regABL : STD_LOGIC_VECTOR(7 downto 0);

    -- ADDRESS MUXES
    signal cp_address_selector : STD_LOGIC_VECTOR(2 downto 0);
    signal address_MSH, address_LSH : STD_LOGIC_VECTOR(7 downto 0);

    -- ALU
    signal ALU_Z : STD_LOGIC_VECTOR(15 downto 0);

    -- IDL
    signal IDL_Z : STD_LOGIC_VECTOR(15 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    from_memory <= data;
    
    address <= address_MSH & address_LSH;


    -------------------------------------------------------------------------------
    -- ADDRESS MUXES
    -------------------------------------------------------------------------------    
    PMUX_ADDRESS: process(cp_address_selector, program_counter_i, from_memory, ALU_Z, IDL_Z, stack_pointer)
    begin
        case cp_address_selector is
            when "000" => 
                address_MSH <= program_counter_i(15 downto 8);
                address_LSH <= program_counter_i(7 downto 0);
            when "001" => 
                -- address_MSH <= regABH;
                -- address_LSH <= regABL;
                address_MSH <= x"00";
                address_LSH <= from_memory;
            when "010" => 
                address_MSH <= ALU_Z(15 downto 8);
                address_LSH <= ALU_Z(7 downto 0);
            when "011" => 
                address_MSH <= IDL_Z(15 downto 8);
                address_LSH <= IDL_Z(7 downto 0);
            when "100" => 
                address_MSH <= program_counter_i(15 downto 8);
                address_LSH <= stack_pointer;
            when "101" => 
                address_MSH <= regABH;
                address_LSH <= stack_pointer;
            when "110" => 
                address_MSH <= ALU_Z(15 downto 8);
                address_LSH <= stack_pointer;
            when others => 
                address_MSH <= IDL_Z(15 downto 8);
                address_LSH <= stack_pointer;
        end case;
    end process;

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
    cp_address_selector <= control_signals(31 downto 29);

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
