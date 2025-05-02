-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Finak Project PART I 
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------
-- FILE: DecoderFinal.vhd
--   This file contains VHDL that implements the decode logic for the 
--   simplified NIOS processor.
-- DESCRIPTION:
--   The decoder extracts the source register numbers, destination register
--   number, 16-bit immediate data, and generates the ALU operation code based
--   on the current 32-bit instruction.
-- COURSE:      Engineering 304
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Decoder IS
    PORT
    (
        Instr  : IN  std_logic_vector(31 downto 0);
        RegRdA : OUT std_logic_vector(4 downto 0);
        RegRdB : OUT std_logic_vector(4 downto 0);
        Imm16  : OUT std_logic_vector(15 downto 0);
        ALUOp  : OUT std_logic_vector(3 downto 0);
        RegWr  : OUT std_logic_vector(4 downto 0)
    );
END Decoder;

ARCHITECTURE DecoderBehavior OF Decoder IS

    -- Internal signals to break out instruction fields
    SIGNAL Instr_OpCode  : std_logic_vector(7 downto 0); -- using 8 bits (6-bit opcode padded)
    SIGNAL Instr_OpXCode : std_logic_vector(7 downto 0); -- using 8 bits (6-bit extended opcode padded)
    SIGNAL Instr_RegA    : std_logic_vector(4 downto 0);
    SIGNAL Instr_RegB    : std_logic_vector(4 downto 0);
    SIGNAL Instr_RegC    : std_logic_vector(4 downto 0);
    SIGNAL Instr_Imm16   : std_logic_vector(15 downto 0);
    SIGNAL Instr_Imm5    : std_logic_vector(4 downto 0);

BEGIN

    -- Extract fields from the 32-bit instruction
    Instr_OpCode  <= "00" & Instr(5 downto 0);
    Instr_OpXCode <= "00" & Instr(16 downto 11);
    Instr_RegA    <= Instr(31 downto 27);
    Instr_RegB    <= Instr(26 downto 22);
    Instr_RegC    <= Instr(21 downto 17);
    Instr_Imm16   <= Instr(21 downto 6);
    Instr_Imm5    <= Instr(10 downto 6);
    
    PROCESS(Instr, Instr_OpCode, Instr_OpXCode, Instr_RegA, Instr_RegB, Instr_RegC, Instr_Imm16, Instr_Imm5)
    BEGIN
        -- Default assignments
        RegRdA <= (others => '0');
        RegRdB <= (others => '0');
        Imm16  <= (others => '0');
        ALUOp  <= (others => '0');
        RegWr  <= (others => '0');
        
        case Instr_OpCode is
            ---------------------------------------------------------------------
            -- I-Type Instructions:
            ---------------------------------------------------------------------
            when x"04" =>  -- addi: Addition (with sign-extended immediate)
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"1";  -- Addition
                
            when x"14" =>  -- ori: OR immediate (zero extend)
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"3";  -- OR operation
                
            when x"0c" =>  -- andi: AND immediate (zero extend)
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"5";  -- AND operation
                
            when x"1c" =>  -- xori: XOR immediate (zero extend)
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"6";  -- XOR operation
                
            when x"34" =>  -- orhi: OR immediate upper
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"9";  -- Using OR op (interpretation for upper immediate)
                
            when x"17" =>  -- ldw: Load word (address calculation via addition)
                RegRdA <= Instr_RegA;
                RegWr  <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"1";  -- Addition
                
            when x"15" =>  -- stw: Store word (address calculation via addition)
                RegRdA <= Instr_RegA;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"1";  -- Addition
                -- No destination register write for a store

            when x"06" =>  -- br: Unconditional branch
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"0";  -- No ALU operation

            when x"26" =>  -- beq: Branch if equal (uses subtraction to compare)
                RegRdA <= Instr_RegA;
                RegRdB <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"2";  -- Subtraction

            when x"1e" =>  -- bne: Branch if not equal (uses subtraction)
                RegRdA <= Instr_RegA;
                RegRdB <= Instr_RegB;
                Imm16  <= Instr_Imm16;
                ALUOp  <= x"2";  -- Subtraction
              
            ---------------------------------------------------------------------
            -- R-Type Instructions (register-to-register operations):
            -- Opcode is x"3a"; the extended opcode (Instr_OpXCode) further 
            -- determines the operation.
            ---------------------------------------------------------------------
            when x"3a" =>
                RegRdA <= Instr_RegA;
                RegRdB <= Instr_RegB;
                RegWr  <= Instr_RegC;
                case Instr_OpXCode is
                    when x"31" =>  -- add
                        ALUOp <= x"1";
                    when x"39" =>  -- sub
                        ALUOp <= x"2";
                    when x"16" =>  -- or
                        ALUOp <= x"3";
                    when x"06" =>  -- nor
                        ALUOp <= x"4";
                    when x"0e" =>  -- and
                        ALUOp <= x"5";
                    when x"1e" =>  -- xor
                        ALUOp <= x"6";
                    when x"12" =>  -- slli (shift left)
                        ALUOp <= x"7";
                    when x"1a" =>  -- srli (shift right)
                        ALUOp <= x"8";
                    when others =>
                        ALUOp <= (others => '0');
                end case;
                
            when others =>
                -- Defaults (all zeros) remain
                null;
        end case;
    END PROCESS;

END DecoderBehavior;


