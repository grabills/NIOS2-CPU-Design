-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/28/25
-- PURPOSE: Final Project PART II 
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------
-- FILE: Controller.vhd
--   This file contains VHDL that implements the decode logic for the 
--   simplified NIOS processor.
-- DESCRIPTION:
--   The decoder extracts the source register numbers, destination register
--   number, 16-bit immediate data, and generates the ALU operation code based
--   on the current 32-bit instruction.
-- COURSE:      Engineering 304
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controller is
    Port (
        Clk         : in  std_logic;
        Reset       : in  std_logic;
        Instr       : in  std_logic_vector(31 downto 0);
        ALUZero     : in  std_logic;
        UpdPC       : out std_logic;
        UpdIR       : out std_logic;
        UpdReg      : out std_logic;
        RegWrMUX    : out std_logic;
        UpdMem      : out std_logic;
        ALUBMUX     : out std_logic;
        BrnchTaken  : out std_logic
    );
end Controller;

architecture Behavioral of Controller is

    type StateType is (
        StartFetch, LoadIR, DecodeOp, CheckBranch, MemAccess, WriteBack
    );

    signal y_present, y_next : StateType;
    signal OpCode : std_logic_vector(5 downto 0);

begin
	OpCode <= Instr(5 downto 0);

    -- State Register
    process(Clk, Reset)
    begin
        if Reset = '0' then
            y_present <= StartFetch;
        elsif rising_edge(Clk) then
            y_present <= y_next;
        end if;
    end process;

    -- Next State Logic
    process(y_present, OpCode)
    begin
        --OpCode <= Instr(5 downto 0);

        case y_present is
            when StartFetch =>
                y_next <= LoadIR;

            when LoadIR =>
                y_next <= DecodeOp;

            when DecodeOp =>
                case OpCode is
                    when "111010" => y_next <= WriteBack;  -- R-type
                    when "010100" => y_next <= WriteBack;  -- I-type
                    when "000100" => y_next <= WriteBack; -- Immediate addi
                    when "110100" => y_next <= WriteBack; -- Immediate muli
                    when "001100" => y_next <= WriteBack; -- Immediate initd
                    when "011100" => y_next <= WriteBack; -- Immediate initd
                    --when "10" => y_next <= CheckBranch; -- Branch
                    when "010101" => y_next <= MemAccess; --stw
                    when "010111" => y_next <= MemAccess; --ldw
                    when others => y_next <= StartFetch;
                end case;
            when CheckBranch =>
                y_next <= StartFetch;

            when MemAccess =>
                y_next <= WriteBack;

            when WriteBack =>
                y_next <= StartFetch;
        end case;
    end process;

    -- Output Logic
    process(y_present, OpCode, ALUZero)
    begin
        -- Default values
        UpdPC      <= '0';
        UpdIR      <= '0';
       -- UpdReg     <= '0';
       -- RegWrMUX   <= '0';
        UpdMem     <= '0';
        ALUBMUX    <= '0';
        BrnchTaken <= '0';

        case y_present is
            when StartFetch =>
                UpdPC <= '1';

            when LoadIR =>
                UpdIR <= '1';

            when DecodeOp =>
                case OpCode is
                    when "111010" => ALUBMUX <= '0'; -- register for R-type
                    when "010100" => ALUBMUX <= '1'; -- Immediate for I-type
                    when "000100" => ALUBMUX <= '1'; -- Immediate addi
                    when "110100" => ALUBMUX <= '1'; -- Immediate muli
                    when "001100" => ALUBMUX <= '1'; -- Immediate initd
                    when "011100" => ALUBMUX <= '1';
                    when "010111" => ALUBMUX <= '1';                

                    when others => ALUBMUX <= '1';
                end case;

            when CheckBranch =>
                if ALUZero = '1' then
                    BrnchTaken <= '1';
                    UpdPC <= '1';
                end if;

            when MemAccess =>
                UpdMem <= '1';  -- Memory access signal

            when WriteBack =>
              case OpCode is
                    when "111010" => ALUBMUX <= '0'; -- register for R-type
                    when "010100" => ALUBMUX <= '1'; -- Immediate for I-type
                    when "000100" => ALUBMUX <= '1'; -- Immediate addi
                    when "110100" => ALUBMUX <= '1'; -- Immediate muli
                    when "001100" => ALUBMUX <= '1'; -- Immediate initd
                    when "011100" => ALUBMUX <= '1';
                    when "010111" => ALUBMUX <= '1';
                    when others => ALUBMUX <= '1';
              end case;
             --   UpdReg <= '1';
              --  RegWrMUX <= '1'; -- ALU result selected
        end case;
    end process;
UpdReg <= '1' when y_present = WriteBack else '0';
RegWrMUX <= '1' when y_present = WriteBack else '0';

end Behavioral;
