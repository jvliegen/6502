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
        data : in STD_LOGIC_VECTOR(7 downto 0);

        verification : out STD_LOGIC_VECTOR(47 downto 0)
    );
end entity processor;

architecture Behavioural of processor is

    component pc is
        port(
            sys_reset_n : in STD_LOGIC;
            clock : in STD_LOGIC;
            inc : in STD_LOGIC;
            ld_LSH : in STD_LOGIC;
            ld_MSH : in STD_LOGIC;
            data_half : in STD_LOGIC_VECTOR(7 downto 0);
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

    component adder is
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
    end component;

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal address_i : STD_LOGIC_VECTOR(15 downto 0);
    signal data_i : STD_LOGIC_VECTOR(7 downto 0);

    -- CONTROL PATH
    signal cp_pc_inc : STD_LOGIC;
    signal cp_pc_ld : STD_LOGIC;
    signal cp_regA_ld : STD_LOGIC;
    signal cp_regABL_ld : STD_LOGIC;
    signal cp_regA_ld_rora : STD_LOGIC;
    signal cp_Cflag_set : STD_LOGIC;
    signal cp_Dflag_set : STD_LOGIC;
    signal cp_Iflag_set : STD_LOGIC;
    signal cp_Cflag_reset : STD_LOGIC;
    signal cp_Dflag_reset : STD_LOGIC;
    signal cp_Iflag_reset : STD_LOGIC;
    signal cp_Vflag_reset : STD_LOGIC;
    signal cp_regX_inc : STD_LOGIC;
    signal cp_regY_inc : STD_LOGIC;
    
    
    -- STACK POINTER
    signal stack_pointer : STD_LOGIC_VECTOR(7 downto 0);
    
    -- PROGRAM COUNTER
    signal program_counter, program_counter_incremented, ripple_carry : STD_LOGIC_VECTOR(15 downto 0);
    signal adder2_b, adder2_ripple_carry, adder2_S : STD_LOGIC_VECTOR(15 downto 0);
    

    signal regX_incremented : STD_LOGIC_VECTOR(7 downto 0);
    signal regY_incremented : STD_LOGIC_VECTOR(7 downto 0);

    -- DECODER
    signal from_memory : STD_LOGIC_VECTOR(7 downto 0);
    signal control_signals : STD_LOGIC_VECTOR(31 downto 0);
    
    -- REGISTERS
    signal regA : STD_LOGIC_VECTOR(7 downto 0);
    signal regX : STD_LOGIC_VECTOR(7 downto 0);
    signal regY : STD_LOGIC_VECTOR(7 downto 0);
    signal regABL : STD_LOGIC_VECTOR(7 downto 0);
    signal flags : STD_LOGIC_VECTOR(5 downto 0);
    alias N_flag : STD_LOGIC is flags(5);
    alias Z_flag : STD_LOGIC is flags(4);
    alias C_flag : STD_LOGIC is flags(3);
    alias I_flag : STD_LOGIC is flags(2);
    alias D_flag : STD_LOGIC is flags(1);
    alias V_flag : STD_LOGIC is flags(0);

    -- ADDRESS MUXES
    signal cp_address_selector : STD_LOGIC_VECTOR(2 downto 0);
    signal cp_LDA_selector : STD_LOGIC_VECTOR(2 downto 0);
    signal address_MSH, address_LSH : STD_LOGIC_VECTOR(7 downto 0);

    -- ALU
    signal ALU_Z : STD_LOGIC_VECTOR(15 downto 0);
    signal zeropageX : STD_LOGIC_VECTOR(7 downto 0);

    -- IDL
    signal IDL_Z : STD_LOGIC_VECTOR(15 downto 0);

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    from_memory <= data;
    
    address <= address_i;
    address_i <= address_MSH & address_LSH;

    verification <= program_counter & regY & regX & regABL & regA;

    -------------------------------------------------------------------------------
    -- ADDRESS MUXES
    -------------------------------------------------------------------------------    
    PMUX_ADDRESS: process(cp_address_selector, program_counter, from_memory, regABL, ALU_Z, IDL_Z, stack_pointer, zeropageX)
    begin
        case cp_address_selector is
            when "000" => 
                address_MSH <= program_counter(15 downto 8);
                address_LSH <= program_counter(7 downto 0);
            when "001" => 
                address_MSH <= x"00";
                address_LSH <= from_memory;
            when "010" => 
                address_MSH <= from_memory;
                address_LSH <= regABL;
            when "011" => 
                address_MSH <= x"00";
                address_LSH <= zeropageX;

            --     address_LSH <= ALU_Z(7 downto 0);
            -- when "011" => 
            --     address_MSH <= IDL_Z(15 downto 8);
            --     address_LSH <= IDL_Z(7 downto 0);
            -- when "100" => 
            --     address_MSH <= program_counter(15 downto 8);
            --     address_LSH <= stack_pointer;
            -- when "101" => 
            --     address_MSH <= x"00";
            --     address_LSH <= stack_pointer;
            -- when "110" => 
            --     address_MSH <= ALU_Z(15 downto 8);
            --     address_LSH <= stack_pointer;
            when others => 
                address_MSH <= IDL_Z(15 downto 8);
                address_LSH <= stack_pointer;
        end case;
    end process;

    -------------------------------------------------------------------------------
    -- PROGRAM COUNTER
    -------------------------------------------------------------------------------
    -- pc_inst00: component pc port map( sys_reset_n => sys_reset_n_i, clock => clock_i,
    --                                   inc => cp_pc_inc, ld_LSH => cp_pc_ld_msh, ld_MSH => cp_pc_ld_lsh, 
    --                                   data_half => from_memory, Z => program_counter_i);

    PREG_PC: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            program_counter <= x"0000";
        elsif rising_edge(clock_i) then 
            if cp_pc_inc = '1' then 
                program_counter <= program_counter_incremented;
            elsif cp_pc_ld = '1' then 
                program_counter <= adder2_S;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------------
    -- DECODER
    -------------------------------------------------------------------------------
    decoder_inst00: component decoder port map( sys_reset_n => sys_reset_n_i, clock => clock_i, A => from_memory, control_signals => control_signals);
    
    cp_pc_inc <= control_signals(0);
    cp_regA_ld <= control_signals(1);
    cp_regABL_ld <= control_signals(2);
    cp_pc_ld <= control_signals(3);
    cp_Cflag_set <= control_signals(4);
    cp_Dflag_set <= control_signals(5);
    cp_Iflag_set <= control_signals(6);
    cp_Cflag_reset <= control_signals(7);
    cp_Dflag_reset <= control_signals(8);
    cp_Iflag_reset <= control_signals(9);
    cp_Vflag_reset <= control_signals(10);
    cp_regX_inc <= control_signals(11);
    cp_regY_inc <= control_signals(12);

    cp_LDA_selector <= control_signals(28 downto 26);
    cp_address_selector <= control_signals(31 downto 29);

    -------------------------------------------------------------------------------
    -- REGISTERS
    -------------------------------------------------------------------------------
    PREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            regA <= x"00";
            regX <= x"00";
            regY <= x"00";
            regABL <= x"00";
            flags <= "000000";
        elsif rising_edge(clock_i) then 
            if cp_regA_ld = '1' then 
                if cp_LDA_selector = "000" then 
                    regA <= from_memory;
                elsif cp_LDA_selector = "001" then 
                    regA <= C_flag & regA(7 downto 1);
                    C_flag <= regA(0);
                elsif cp_LDA_selector = "010" then 
-- THIS SHOULD BE CHANGED TO: ALU OUTPUT
                    regA <= regA OR from_memory;
                end if;
            end if;

            if cp_regX_inc = '1' then 
                regX <= regX_incremented;
            end if;
            if cp_regY_inc = '1' then 
                regY <= regY_incremented;
            end if;

            if cp_regABL_ld = '1' then 
                regABL <= from_memory;
            end if;

            if cp_Cflag_set = '1' then 
                C_flag <= '1';
            elsif cp_Cflag_reset = '1' then
                C_flag <= '0';
            end if;

            if cp_Dflag_set = '1' then 
                D_flag <= '1';
            elsif cp_Dflag_reset = '1' then
                D_flag <= '0';
            end if;

            if cp_Iflag_set = '1' then 
                I_flag <= '1';
            elsif cp_Iflag_reset = '1' then
                I_flag <= '0';
            end if;


            if cp_Vflag_reset = '1' then
                V_flag <= '0';
            end if;

        end if;
    end process;

    
    -------------------------------------------------------------------------------
    -- ADDERS
    -------------------------------------------------------------------------------
    -- These are multiple adders. Some of them have a fixed term and could be
    -- optimised. 
    -- TODO: see how to combine in a single ALU
    --       maybe with exception for the 16-bit adder for the PC

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

    adder2_B <= from_memory & regABL;
    adder2_S(0) <= not(adder2_B(0));                             adder2_ripple_carry(1) <= adder2_B(0);
    adder2_S(1) <= adder2_B(1) XOR adder2_ripple_carry(1);       adder2_ripple_carry(2) <= adder2_B(1) AND adder2_ripple_carry(1);
    adder2_S(2) <= adder2_B(2) XOR adder2_ripple_carry(2);       adder2_ripple_carry(3) <= adder2_B(2) AND adder2_ripple_carry(2);
    adder2_S(3) <= adder2_B(3) XOR adder2_ripple_carry(3);       adder2_ripple_carry(4) <= adder2_B(3) AND adder2_ripple_carry(3);
    adder2_S(4) <= adder2_B(4) XOR adder2_ripple_carry(4);       adder2_ripple_carry(5) <= adder2_B(4) AND adder2_ripple_carry(4);
    adder2_S(5) <= adder2_B(5) XOR adder2_ripple_carry(5);       adder2_ripple_carry(6) <= adder2_B(5) AND adder2_ripple_carry(5);
    adder2_S(6) <= adder2_B(6) XOR adder2_ripple_carry(6);       adder2_ripple_carry(7) <= adder2_B(6) AND adder2_ripple_carry(6);
    adder2_S(7) <= adder2_B(7) XOR adder2_ripple_carry(7);       adder2_ripple_carry(8) <= adder2_B(7) AND adder2_ripple_carry(7);
    adder2_S(8) <= adder2_B(8) XOR adder2_ripple_carry(8);       adder2_ripple_carry(9) <= adder2_B(8) AND adder2_ripple_carry(8);
    adder2_S(9) <= adder2_B(9) XOR adder2_ripple_carry(9);       adder2_ripple_carry(10) <= adder2_B(9) AND adder2_ripple_carry(9);
    adder2_S(10) <= adder2_B(10) XOR adder2_ripple_carry(10);    adder2_ripple_carry(11) <= adder2_B(10) AND adder2_ripple_carry(10);
    adder2_S(11) <= adder2_B(11) XOR adder2_ripple_carry(11);    adder2_ripple_carry(12) <= adder2_B(11) AND adder2_ripple_carry(11);
    adder2_S(12) <= adder2_B(12) XOR adder2_ripple_carry(12);    adder2_ripple_carry(13) <= adder2_B(12) AND adder2_ripple_carry(12);
    adder2_S(13) <= adder2_B(13) XOR adder2_ripple_carry(13);    adder2_ripple_carry(14) <= adder2_B(13) AND adder2_ripple_carry(13);
    adder2_S(14) <= adder2_B(14) XOR adder2_ripple_carry(14);    adder2_ripple_carry(15) <= adder2_B(14) AND adder2_ripple_carry(14);
    adder2_S(15) <= adder2_B(15) XOR adder2_ripple_carry(15);


    adder_incX: component adder generic map(G_WIDTH => 8) port map(
        A => regX, B => x"01", Cin => '0',
        Z => regX_incremented, Cout => open
    );

    adder_incY: component adder generic map(G_WIDTH => 8) port map(
        A => regY, B => x"01", Cin => '0',
        Z => regY_incremented, Cout => open
    );

    adder_zeropageX: component adder generic map(G_WIDTH => 8) port map(
        A => regX, B => from_memory, Cin => '0',
        Z => zeropageX, Cout => open
    );




end Behavioural;
