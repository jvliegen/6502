--------------------------------------------------------------------------------
-- KU Leuven - ESAT/COSIC- Embedded Systems & Security
--------------------------------------------------------------------------------
-- Module Name:     processor_tb - Behavioural
-- Project Name:    6502
-- Description:     Testbench for the processor
--
-- Revision     Date       Author     Comments
-- v0.1         20220505   VlJo       Initial version
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use STD.textio.all;
    use ieee.std_logic_textio.all;

entity processor_tb is
end entity processor_tb;

architecture Behavioural of processor_tb is

    component processor is
        port(
            sys_reset_n : in STD_LOGIC;
            clock : in STD_LOGIC;
            address : out STD_LOGIC_VECTOR(15 downto 0);
            data : in STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal sys_reset_n : STD_LOGIC;
    signal clock : STD_LOGIC;
    signal address : STD_LOGIC_VECTOR(15 downto 0);
    signal data : STD_LOGIC_VECTOR(7 downto 0);

    file fh : text;
    signal addr_int : integer range 0 to 16384-1;
    signal mem_content : STD_LOGIC_VECTOR(7 downto 0);
    type T_memory is array(0 to 16384-1) of STD_LOGIC_VECTOR(7 downto 0);
    signal mem : T_memory;

    constant FNAME_HEX : string := "/home/jvliegen/vc/github/jvliegen/6502/firmware/firmware.hex";
    constant clock_period : time := 10 ns;
    
begin

    -------------------------------------------------------------------------------
    -- STIMULI
    -------------------------------------------------------------------------------
    PSTIM: process
    begin
        sys_reset_n <= '0';
        wait for clock_period * 10;

        sys_reset_n <= '1';
        wait for clock_period * 10;


        wait;
    end process;

    -------------------------------------------------------------------------------
    -- DUT
    -------------------------------------------------------------------------------
    DUT: component processor port map(
        sys_reset_n => sys_reset_n,
        clock => clock,
        address => address, 
        data => data
    );

    -------------------------------------------------------------------------------
    -- MEMORY
    -------------------------------------------------------------------------------
    addr_int <= to_integer(unsigned(address(13 downto 0)));
    mem_content <= mem(addr_int);
    
    PMEM: process(sys_reset_n, clock)
        variable v_line : line;
        variable v_temp : STD_LOGIC_VECTOR(7 downto 0);
        variable v_pointer : integer;
    begin
        if sys_reset_n = '0' then 
            data <= (others => '0');
            mem <= (others => (others => '0'));

            -- init the firmware
            v_pointer := 0;
            file_open(fh, FNAME_HEX, read_mode);

            while not endfile(fh) loop
                readline(fh, v_line);
                hread(v_line, v_temp);
                mem(v_pointer) <= v_temp;
                v_pointer := v_pointer + 1;
            end loop;

            file_close(fh);
        elsif rising_edge(clock) then 
            -- -- write to memory
            -- if load_reg_write = '1' then 
            --     mem(addr_int) <= masked_data OR mem_content;
            --     data <= (others => '0');
            -- end if;

            -- read from memory 
            -- if load_reg_read = '1' then 
            data <= mem_content;
            -- end if;

        end if;
    end process;


    -------------------------------------------------------------------------------
    -- CLOCK
    -------------------------------------------------------------------------------
    PCLK: process
    begin
        clock <= '1';
        wait for clock_period/2;
        clock <= '0';
        wait for clock_period/2;
    end process PCLK;

end Behavioural;
