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
        ROR_A, SEC, SED, SEI, CLC, CLD, CLI, CLV,
        INX, INY,
        ORA_immediate, ORA_zeropage, ORA_zeropageX
    );
    signal mnemonic, curOpCode : TMNEMONIC;

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal A_i : STD_LOGIC_VECTOR(7 downto 0);
    

    -- CONTROL PATH
    type Tstates is (sReset,
        sFetch_instruction,
        sLDA_fetch_immediate,
        sFetch_zeropage_ABL_andClearABH, sFetch_zeropage_data,
        sFetch_zeropageX_ABLplusX_andClearABH, sFetch_zeropageX_data,
        sFetch_absolute_ABL, sFetch_absolute_ABH, sFetch_absolute_data,
        sFetch_absoluteX_ABL, sFetch_absoluteX_ABH, sFetch_absoluteX_data,
        sFetch_absoluteY_ABL, sFetch_absoluteY_ABH, sFetch_absoluteY_data,
        sFetch_jump_absolute_fetchABL, sFetch_jump_absolute_fetchABH,
        sINX, sINY,
        sROR_a,
        sSEC, sSED, sSEI,
        sCLC, sCLD, sCLI, sCLV,
        sORA_fetch_immediate,
        sORA_zeropage_ABL_andClearABH, sORA_zeropage_data,
        sORA_zeropageX_ABLplusX_andClearABH, sORA_zeropageX_data,
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
    signal cp_LDA_selector : STD_LOGIC_VECTOR(2 downto 0);
    signal cp_Cflag_set : STD_LOGIC;
    signal cp_Dflag_set : STD_LOGIC;
    signal cp_Iflag_set : STD_LOGIC;
    signal cp_regX_inc : STD_LOGIC;
    signal cp_regY_inc : STD_LOGIC;

    signal cp_Cflag_reset : STD_LOGIC;
    signal cp_Dflag_reset : STD_LOGIC;
    signal cp_Iflag_reset : STD_LOGIC;
    signal cp_Vflag_reset : STD_LOGIC;

    signal allow_pc_inc_with_fetch : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    A_i <= A;
    control_signals <= cp_address_selector & cp_LDA_selector & "000" & x"00" & "00" & 
    cp_regY_inc & cp_regX_inc & 
    cp_Vflag_reset & cp_Iflag_reset & cp_Dflag_reset & cp_Cflag_reset & cp_Iflag_set & cp_Dflag_set & cp_Cflag_set & 
    cp_pc_ld & cp_pc_ld_lsh & 
    cp_regA_ld & 
    cp_pc_inc;

    -- Sometimes it's interesting if the automatic INC of the PC is not doen
    -- while doing the fetch. This if for operations that only require 1 byte.
    -- The automatic INC can thusly be overriden.
    -- Flaging this happens in the decoder (allow_pc_inc_with_fetch)
    cp_pc_inc <= (cp_pc_inc_with_fetch and allow_pc_inc_with_fetch) or cp_pc_inc_instr;

    -------------------------------------------------------------------------------
    -- DECODER
    -------------------------------------------------------------------------------
    PMUX: process(A_i)
    begin
        allow_pc_inc_with_fetch <= '1';
        case A_i is
            -- LDA: Load Accumulator with Memory
            when x"A9" => mnemonic <= LDA_immediate;
            when x"A5" => mnemonic <= LDA_zeropage;
            when x"B5" => mnemonic <= LDA_zeropageX;
            when x"AD" => mnemonic <= LDA_absolute;
            when x"BD" => mnemonic <= LDA_absoluteX;
            when x"B9" => mnemonic <= LDA_absoluteY;
            when x"4C" => mnemonic <= JMP_absolute;

            when x"6A" => mnemonic <= ROR_A; allow_pc_inc_with_fetch <= '0';
            when x"38" => mnemonic <= SEC; allow_pc_inc_with_fetch <= '0';
            when x"F8" => mnemonic <= SED; allow_pc_inc_with_fetch <= '0';
            when x"78" => mnemonic <= SEI; allow_pc_inc_with_fetch <= '0';

            when x"18" => mnemonic <= CLC; allow_pc_inc_with_fetch <= '0';
            when x"D8" => mnemonic <= CLD; allow_pc_inc_with_fetch <= '0';
            when x"58" => mnemonic <= CLI; allow_pc_inc_with_fetch <= '0';
            when x"B8" => mnemonic <= CLV; allow_pc_inc_with_fetch <= '0';

            when x"09" => mnemonic <= ORA_immediate;
            when x"05" => mnemonic <= ORA_zeropage;
            when x"15" => mnemonic <= ORA_zeropageX;

            when x"E8" => mnemonic <= INX; allow_pc_inc_with_fetch <= '0';
            when x"C8" => mnemonic <= INY; allow_pc_inc_with_fetch <= '0';

            when others => mnemonic <= XXX;
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
                    nxtState <= sLDA_fetch_immediate;
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

                elsif mnemonic = CLC then 
                    nxtState <= sCLC;
                elsif mnemonic = CLD then 
                    nxtState <= sCLD;
                elsif mnemonic = CLI then 
                    nxtState <= sCLI;
                elsif mnemonic = CLV then 
                    nxtState <= sCLV;

                elsif mnemonic = ORA_immediate then 
                    nxtState <= sORA_fetch_immediate;
                elsif mnemonic = ORA_zeropage then 
                    nxtState <= sORA_zeropage_ABL_andClearABH;
                elsif mnemonic = ORA_zeropageX then 
                    nxtState <= sORA_zeropageX_ABLplusX_andClearABH;


                elsif mnemonic = INX then 
                    nxtState <= sINX;
                elsif mnemonic = INY then 
                    nxtState <= sINY;
                else
                    nxtState <= sTrap;
                end if;

            when sLDA_fetch_immediate => nxtState <= sFetch_instruction;
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

            when sORA_fetch_immediate => nxtState <= sFetch_instruction;
            when sORA_zeropage_ABL_andClearABH => nxtState <= sORA_zeropage_data;
            when sORA_zeropage_data => nxtState <= sFetch_instruction;
            when sORA_zeropageX_ABLplusX_andClearABH => nxtState <= sORA_zeropageX_data;
            when sORA_zeropageX_data => nxtState <= sFetch_instruction;






            when sFetch_jump_absolute_fetchABL => nxtState <= sFetch_jump_absolute_fetchABH;
            when sFetch_jump_absolute_fetchABH => nxtState <= sFetch_instruction;

            when sROR_a => nxtState <= sFetch_instruction;
            when sSEC => nxtState <= sFetch_instruction;
            when sSED => nxtState <= sFetch_instruction;
            when sSEI => nxtState <= sFetch_instruction;

            when sCLC => nxtState <= sFetch_instruction;
            when sCLD => nxtState <= sFetch_instruction;
            when sCLI => nxtState <= sFetch_instruction;
            when sCLV => nxtState <= sFetch_instruction;

            when sINX => nxtState <= sFetch_instruction;
            when sINY => nxtState <= sFetch_instruction;


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
        cp_LDA_selector <= "000";
        cp_pc_ld_lsh <= '0';
        cp_pc_ld <= '0';
        cp_Cflag_set <= '0';
        cp_Dflag_set <= '0';
        cp_Iflag_set <= '0';
        cp_Cflag_reset <= '0';
        cp_Dflag_reset <= '0';
        cp_Iflag_reset <= '0';
        cp_Vflag_reset <= '0';
        cp_regX_inc <= '0';
        cp_regY_inc <= '0';

        case curState is

            when sFetch_instruction =>                      cp_pc_inc_with_fetch <= '1';

            -- different LDAs
            when sLDA_fetch_immediate =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "000";
                                                                              -- here the address source is set to ABH and ABL, so it's ready 
                                                                              -- at the next cycle for loading
            when sFetch_zeropage_ABL_andClearABH =>         cp_pc_inc_instr <= '0'; cp_address_selector <= "001";
                                                                              -- while the indirect memory is stored, the address source is
                                                                              -- set again to the PC to be able to fetch in the next clock cycle
            when sFetch_zeropage_data =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "000";

            when sFetch_zeropageX_ABLplusX_andClearABH =>   cp_pc_inc_instr <= '0'; cp_address_selector <= "001";
            when sFetch_zeropageX_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "000";
            
            when sFetch_absolute_ABL =>                     cp_pc_inc_instr <= '1';
            when sFetch_absolute_ABH =>                     cp_pc_inc_instr <= '1';                      
            when sFetch_absolute_data =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "000"; cp_address_selector <= "001";

            when sFetch_absoluteX_ABL =>                    cp_pc_inc_instr <= '1';
            when sFetch_absoluteX_ABH =>                    cp_pc_inc_instr <= '1';                      
            when sFetch_absoluteX_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "000"; cp_address_selector <= "001";

            when sFetch_absoluteY_ABL =>                    cp_pc_inc_instr <= '1';
            when sFetch_absoluteY_ABH =>                    cp_pc_inc_instr <= '1';                      
            when sFetch_absoluteY_data =>                   cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';  cp_LDA_selector <= "000";cp_address_selector <= "001";

            -- different ORAs
            when sORA_fetch_immediate =>                    cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "010";

            when sORA_zeropage_ABL_andClearABH =>           cp_pc_inc_instr <= '0'; cp_address_selector <= "001";
            when sORA_zeropage_data =>                      cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "010";

            -- when 
            when sORA_zeropageX_ABLplusX_andClearABH =>     cp_pc_inc_instr <= '0'; cp_address_selector <= "011";
            when sORA_zeropageX_data =>                     cp_pc_inc_instr <= '1'; cp_regA_ld <= '1'; cp_LDA_selector <= "010";








            when sFetch_jump_absolute_fetchABL =>           cp_pc_inc_instr <= '1'; cp_pc_ld_lsh <= '1';
            when sFetch_jump_absolute_fetchABH =>           cp_pc_ld <= '1'; cp_address_selector <= "010";

            
            when sROR_a =>                                  cp_pc_inc_instr <= '1'; cp_regA_ld <= '1';  cp_LDA_selector <= "001";
            when sSEC =>                                    cp_pc_inc_instr <= '1'; cp_Cflag_set <= '1';
            when sSED =>                                    cp_pc_inc_instr <= '1'; cp_Dflag_set <= '1';
            when sSEI =>                                    cp_pc_inc_instr <= '1'; cp_Iflag_set <= '1';
            when sCLC =>                                    cp_pc_inc_instr <= '1'; cp_Cflag_reset <= '1';
            when sCLD =>                                    cp_pc_inc_instr <= '1'; cp_Dflag_reset <= '1';
            when sCLI =>                                    cp_pc_inc_instr <= '1'; cp_Iflag_reset <= '1';
            when sCLV =>                                    cp_pc_inc_instr <= '1'; cp_Vflag_reset <= '1';

            when sINX =>                                    cp_pc_inc_instr <= '1'; cp_regX_inc <= '1';
            when sINY =>                                    cp_pc_inc_instr <= '1'; cp_regY_inc <= '1';

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
        elsif rising_edge(clock_i) then 
            curState <= nxtState;
            if curState = sFetch_instruction then 
                curOpCode <= mnemonic;
            end if;
        end if;
    end process;

end Behavioural;
