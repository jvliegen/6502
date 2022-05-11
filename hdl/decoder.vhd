--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     decoder - Behavioural
-- Project Name:    6502
-- Description:     This component describes the decoder
--
-- Revision     Date       Author     Comments
-- v0.1         20220505   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    -- use IEEE.NUMERIC_STD.ALL;


entity decoder is
    port (
        sys_reset_n : in STD_LOGIC;
        clock : in STD_LOGIC;
        A : in STD_LOGIC_VECTOR(7 downto 0);
        control_signals : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity decoder;

architecture Behavioural of decoder is

    type TMNEMONIC is (XXX,
        LDA_immediate, LDA_zeropage, LDA_zeropageX, LDA_absolute, LDA_absoluteX, LDA_absoluteY, JMP_absolute,
        ROR_A, SEC, SED, SEI
    );
    signal mnemonic, curOpCode : TMNEMONIC;

    signal target, curTarget : STD_LOGIC_VECTOR(7 downto 0);

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal A_i : STD_LOGIC_VECTOR(7 downto 0);
    

    -- CONTROL PATH
    type Tstates is (sReset,
        sFetch_instruction,
        sFetch_immediate,
        sFetch_zeropage_ABL_andClearABH, sFetch_zeropage_data,
        sFetch_zeropageX_ABLplusX_andClearABH, sFetch_zeropageX_data,
        sFetch_absolute_ABL, sFetch_absolute_ABH, sFetch_absolute_data,
        sFetch_absoluteX_ABL, sFetch_absoluteX_ABH, sFetch_absoluteX_data,
        sFetch_absoluteY_ABL, sFetch_absoluteY_ABH, sFetch_absoluteY_data,
        sFetch_jump_absolute_fetchABL, sFetch_jump_absolute_fetchABH,
        sROR_a,
        sSEC, sSED, sSEI,
        sTrap
    );
    signal curState, nxtState : Tstates;

    signal cp_pc_inc : STD_LOGIC;
    signal cp_pc_inc_instr : STD_LOGIC;
    signal cp_pc_inc_with_fetch : STD_LOGIC;
    signal cp_pc_ld_lsh : STD_LOGIC;
    signal cp_pc_ld : STD_LOGIC;
    signal cp_regA_ld : STD_LOGIC;
    signal cp_regABL_ld : STD_LOGIC;
    signal cp_address_selector : STD_LOGIC_VECTOR(2 downto 0);
    signal cp_regA_ld_rora : STD_LOGIC;
    signal cp_Cflag_set : STD_LOGIC;
    signal cp_Dflag_set : STD_LOGIC;
    signal cp_Iflag_set : STD_LOGIC;

    signal allow_pc_inc_with_fetch : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    A_i <= A;
    control_signals <= cp_address_selector & '0' & x"00000" & cp_Iflag_set & cp_Dflag_set & cp_Cflag_set & cp_regA_ld_rora & cp_pc_ld & cp_pc_ld_lsh & cp_regA_ld & cp_pc_inc;

    -- Sometimes it's interesting if the automatic INC of the PC is not doen
    -- while doing the fetch. This if for operations that only require 1 byte.
    -- The automatic INC can thusly be overriden.
    -- Flaging this happens in the decoder (allow_pc_inc_with_fetch)
    cp_pc_inc <= (cp_pc_inc_with_fetch and allow_pc_inc_with_fetch) or cp_pc_inc_instr;

    -------------------------------------------------------------------------------
    -- DECODER
    --    target is ONE-HOT encoded: (0) regA, (3) PC LSH, (4)
    -------------------------------------------------------------------------------
    PMUX: process(A_i)
    begin
        allow_pc_inc_with_fetch <= '1';
        case A_i is
            -- LDA: Load Accumulator with Memory
            when x"A9" => mnemonic <= LDA_immediate; target <= x"01";
            when x"A5" => mnemonic <= LDA_zeropage; target <= x"01";
            when x"B5" => mnemonic <= LDA_zeropageX; target <= x"01";
            when x"AD" => mnemonic <= LDA_absolute; target <= x"01";
            when x"BD" => mnemonic <= LDA_absoluteX; target <= x"01";
            when x"B9" => mnemonic <= LDA_absoluteY; target <= x"01";
            when x"4C" => mnemonic <= JMP_absolute; target <= x"08";

            when x"6A" => mnemonic <= ROR_A; target <= x"08"; allow_pc_inc_with_fetch <= '0';
            when x"38" => mnemonic <= SEC; allow_pc_inc_with_fetch <= '0';
            when x"F8" => mnemonic <= SED; allow_pc_inc_with_fetch <= '0';
            when x"78" => mnemonic <= SEI; allow_pc_inc_with_fetch <= '0';


            when others => mnemonic <= XXX; target <= x"00";
        end case;
    end process;

    -------------------------------------------------------------------------------
    -- CONTROL PATH
    -------------------------------------------------------------------------------


    -- FSM NEXT STATE FUNCTION
    P_FSM_NSF: process(curState, mnemonic)
    begin
        nxtState <= curState;
        case curState is
            when sReset => nxtState <= sFetch_instruction;
            when sFetch_instruction => 
                if mnemonic = LDA_immediate then 
                    nxtState <= sFetch_immediate;
                elsif mnemonic = LDA_zeropage then 
                    nxtState <= sFetch_zeropage_ABL_andClearABH;
                elsif mnemonic = LDA_zeropageX then 
                    nxtState <= sFetch_zeropageX_ABLplusX_andClearABH;
                elsif mnemonic = LDA_absolute then 
                    nxtState <= sFetch_absolute_ABL;
                elsif mnemonic = LDA_absoluteX then 
                    nxtState <= sFetch_absoluteX_ABL;
                elsif mnemonic = LDA_absoluteY then 
                    nxtState <= sFetch_absoluteY_ABL;
                elsif mnemonic = JMP_absolute then 
                    nxtState <= sFetch_jump_absolute_fetchABL;
                elsif mnemonic = ROR_A then 
                    nxtState <= sROR_a;                    

                elsif mnemonic = SEC then 
                    nxtState <= sSEC;
                elsif mnemonic = SED then 
                    nxtState <= sSED;
                elsif mnemonic = SEI then 
                    nxtState <= sSEI;
                else
                    nxtState <= sTrap;
                end if;

            when sFetch_immediate => nxtState <= sFetch_instruction;

            when sFetch_zeropage_ABL_andClearABH => nxtState <= sFetch_zeropage_data;
            when sFetch_zeropage_data => nxtState <= sFetch_instruction;
            
            when sFetch_zeropageX_ABLplusX_andClearABH => nxtState <= sFetch_zeropageX_data;
            when sFetch_zeropageX_data => nxtState <= sFetch_instruction;
            
            when sFetch_absolute_ABL => nxtState <= sFetch_absolute_ABH;
            when sFetch_absolute_ABH => nxtState <= sFetch_absolute_data;
            when sFetch_absolute_data => nxtState <= sFetch_instruction;

            when sFetch_absoluteX_ABL => nxtState <= sFetch_absoluteX_ABH;
            when sFetch_absoluteX_ABH => nxtState <= sFetch_absoluteX_data;
            when sFetch_absoluteX_data => nxtState <= sFetch_instruction;

            when sFetch_absoluteY_ABL => nxtState <= sFetch_absoluteY_ABH;
            when sFetch_absoluteY_ABH => nxtState <= sFetch_absoluteY_data;
            when sFetch_absoluteY_data => nxtState <= sFetch_instruction;

            when sFetch_jump_absolute_fetchABL => nxtState <= sFetch_jump_absolute_fetchABH;
            when sFetch_jump_absolute_fetchABH => nxtState <= sFetch_instruction;

            when sROR_a => nxtState <= sFetch_instruction;
            when sSEC => nxtState <= sFetch_instruction;
            when sSED => nxtState <= sFetch_instruction;
            when sSEI => nxtState <= sFetch_instruction;


            when others => nxtState <= sTrap;
        end case;
    end process;

    -- FSM OUTPUT FUNCTION
    P_FSM_OF_nxt: process(curState)
    begin
        cp_pc_inc_instr <= '0';
        cp_pc_inc_with_fetch <= '0';
        cp_regABL_ld <= '0';
        cp_regA_ld <= '0';
        cp_address_selector <= "000";
        cp_pc_ld_lsh <= '0';
        cp_pc_ld <= '0';
        cp_regA_ld_rora <= '0';
        cp_Cflag_set <= '0';
        case curState is

            when sFetch_instruction =>                      cp_pc_inc_with_fetch <= '1';

            when sFetch_immediate =>                        cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';


                                                                              -- here the address source is set to ABH and ABL, so it's ready 
                                                                              -- at the next cycle for loading
            when sFetch_zeropage_ABL_andClearABH =>         cp_pc_inc_instr <= '0'; cp_address_selector <= "001";
                                                                              -- while the indirect memory is stored, the address source is
                                                                              -- set again to the PC to be able to fetch in the next clock cycle
            when sFetch_zeropage_data =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';
            


            when sFetch_zeropageX_ABLplusX_andClearABH =>   cp_pc_inc_instr <= '0'; cp_address_selector <= "001";
            when sFetch_zeropageX_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';
            
            when sFetch_absolute_ABL =>                     cp_pc_inc_instr <= '1';
            when sFetch_absolute_ABH =>                     cp_pc_inc_instr <= '1';                      
            when sFetch_absolute_data =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';  cp_address_selector <= "001";

            when sFetch_absoluteX_ABL =>                    cp_pc_inc_instr <= '1';
            when sFetch_absoluteX_ABH =>                    cp_pc_inc_instr <= '1';                      
            when sFetch_absoluteX_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';  cp_address_selector <= "001";

            when sFetch_absoluteY_ABL =>                    cp_pc_inc_instr <= '1';
            when sFetch_absoluteY_ABH =>                    cp_pc_inc_instr <= '1';                      
            when sFetch_absoluteY_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';  cp_address_selector <= "001";

            when sFetch_jump_absolute_fetchABL =>           cp_pc_inc_instr <= '1'; cp_pc_ld_lsh <= '1';
            when sFetch_jump_absolute_fetchABH =>           cp_pc_ld <= '1'; cp_address_selector <= "010";

            
            when sROR_a =>                                  cp_pc_inc_instr <= '1'; cp_regA_ld_rora <= '1';
            when sSEC =>                                    cp_pc_inc_instr <= '1'; cp_Cflag_set <= '1';
            when sSED =>                                    cp_pc_inc_instr <= '1'; cp_Dflag_set <= '1';
            when sSEI =>                                    cp_pc_inc_instr <= '1'; cp_Iflag_set <= '1';

            when sReset =>                                  cp_pc_inc_instr <= '1';

            -- also for sTrap
            when others => 
        end case;
    end process;




    -- FSM STATE REGISTER
    P_FSM_STATEREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            curState <= sReset;
            curOpCode <= XXX;
            curTarget <= x"00";
        elsif rising_edge(clock_i) then 
            curState <= nxtState;
            if curState = sFetch_instruction then 
                curOpCode <= mnemonic;
                curTarget <= target;
            end if;
        end if;
    end process;

end Behavioural;
