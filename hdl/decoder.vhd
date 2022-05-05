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

    type TMNEMONIC is (LDA_imm, XXX);
    signal mnemonic, curOpCode : TMNEMONIC;

    -- (DE-)LOCALISING IN/OUTPUTS
    signal sys_reset_n_i : STD_LOGIC;
    signal clock_i : STD_LOGIC;
    signal A_i : STD_LOGIC_VECTOR(7 downto 0);
    signal control_signals_i : STD_LOGIC_VECTOR(31 downto 0);
    
    signal exec_time_i : STD_LOGIC_VECTOR(3 downto 0);
    signal mem_req_i : STD_LOGIC_VECTOR(3 downto 0);

    -- CONTROL PATH
    type Tstates is (sReset, sFetch, sLDA_alpha, sTrap);
    signal curState, nxtState : Tstates;

    signal cp_pc_inc : STD_LOGIC;
    signal cp_regA_ld_immediate : STD_LOGIC;

begin

    -------------------------------------------------------------------------------
    -- (DE-)LOCALISING IN/OUTPUTS
    -------------------------------------------------------------------------------
    sys_reset_n_i <= sys_reset_n;
    clock_i <= clock;
    A_i <= A;
    control_signals <= x"0000000" & "00" & cp_regA_ld_immediate & cp_pc_inc;

    -------------------------------------------------------------------------------
    -- DECODER
    -------------------------------------------------------------------------------
    PMUX: process(A_i)
    begin
        case A_i is
            when x"A9" => mnemonic <= LDA_imm;
            when others => mnemonic <= XXX;
        end case;
    end process;

    -------------------------------------------------------------------------------
    -- CONTROL PATH
    -------------------------------------------------------------------------------


    -- FSM STATE REGISTER
    P_FSM_STATEREG: process(sys_reset_n_i, clock_i)
    begin
        if sys_reset_n_i = '0' then 
            curState <= sReset;
            curOpCode <= XXX;
        elsif rising_edge(clock_i) then 
            curState <= nxtState;
            if curState = sFetch then 
                curOpCode <= mnemonic;
            end if;
        end if;
    end process;

    -- FSM OUTPUT FUNCTION
    cp_pc_inc <= '1' when nxtState = sFetch or nxtState = sLDA_alpha else '0';
    cp_regA_ld_immediate <= '1' when curState = sLDA_alpha else '0';

    -- FSM NEXT STATE FUNCTION
    P_FSM_NSF: process(curState, mnemonic)
    begin
        nxtState <= curState;
        case curState is
            when sReset => nxtState <= sFetch;
            when sFetch => 
                if mnemonic = LDA_imm then 
                    nxtState <= sLDA_alpha;
                else
                    nxtState <= sTrap;
                end if;

            when sLDA_alpha  => nxtState <= sFetch;



            when others => nxtState <= sTrap;
        end case;
    end process;

end Behavioural;
