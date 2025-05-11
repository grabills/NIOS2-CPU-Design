-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Final Project PART III
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------


library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controller is
    Port (
        Clk         : in  std_logic;                     -- Clock signal
        Reset       : in  std_logic;                     -- Active-low reset
        Instr       : in  std_logic_vector(31 downto 0); -- Instruction input
        ALUZero     : in  std_logic;                     -- ALU zero flag for branches
        UpdPC       : out std_logic;                     -- Update PC control
        UpdIR       : out std_logic;                     -- Update IR control
        UpdReg      : out std_logic;                     -- Update register file
        RegWrMUX    : out std_logic;                     -- MUX: ALU result or memory data
        UpdMem      : out std_logic;                     -- Update memory write
        ALUBMUX     : out std_logic;                     -- MUX: Register B or immediate
        BrnchTaken  : out std_logic;                     -- Branch signal
        StateOut    : out std_logic_vector(7 downto 0)   -- LED output for FSM state
    );
end Controller;

architecture Behavioral of Controller is

    type StateType is (
        StartFetch, LoadIR, DecodeOp, CheckBranch, MemAccess, WriteBack
    );

    signal y_present, y_next : StateType;
    signal OpCode : std_logic_vector(5 downto 0);

begin

    OpCode <= Instr(5 downto 0);  -- Extract opcode from instruction

    -- State Register (synchronous reset)
    process(Clk, Reset)
    begin
        if Reset = '0' then
            y_present <= StartFetch;
        elsif rising_edge(Clk) then
            y_present <= y_next;
        end if;
    end process;

    -- Next-State Logic
    process(y_present, OpCode)
    begin
        case y_present is
            when StartFetch =>
                y_next <= LoadIR;

            when LoadIR =>
                y_next <= DecodeOp;

            when DecodeOp =>
                case OpCode is
                    when "111010" => y_next <= WriteBack;   -- R-type
                    when "010100" => y_next <= WriteBack;   -- I-type
                    when "000100" => y_next <= WriteBack;   -- addi
                    when "110100" => y_next <= WriteBack;   -- muli
                    when "001100" => y_next <= WriteBack;   -- initd
                    when "011100" => y_next <= WriteBack;   -- subi
                    when "100110" => y_next <= CheckBranch; -- beq
                    when "011110" => y_next <= CheckBranch; -- bne
                    when "000110" => y_next <= CheckBranch; -- j
                    when "010101" => y_next <= MemAccess;   -- stw
                    when "010111" => y_next <= MemAccess;   -- ldw
                    when others   => y_next <= StartFetch;
                end case;

            when CheckBranch =>
                y_next <= StartFetch;

            when MemAccess =>
                if OpCode = "010101" then       -- stw
                    y_next <= StartFetch;
                elsif OpCode = "010111" then    -- ldw
                    y_next <= WriteBack;
                else
                    y_next <= StartFetch;
                end if;

            when WriteBack =>
                y_next <= StartFetch;
        end case;
    end process;

    -- Output Logic for control signals
    process(y_present, OpCode, ALUZero)
    begin
        -- Defaults
        UpdPC      <= '0';
        UpdIR      <= '0';
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
                    when "111010" => ALUBMUX <= '0';  -- R-type
                    when others   => ALUBMUX <= '1';  -- Immediate-based
                end case;

            when CheckBranch =>
                case OpCode is
                    when "100110" =>             -- beq
                        if ALUZero = '1' then
                            BrnchTaken <= '1';
                        end if;
                    when "011110" =>             -- bne
                        if ALUZero = '0' then
                            BrnchTaken <= '1';
                        end if;
                    when "000110" =>             -- j
                        BrnchTaken <= '1';
                    when others =>
                        BrnchTaken <= '0';
                end case;

            when MemAccess =>
                if OpCode = "010101" then        -- stw
                    UpdMem <= '1';
                end if;
                ALUBMUX <= '1';                  -- Addr calc uses immediate

            when WriteBack =>
                case OpCode is
                    when "111010" => ALUBMUX <= '0';
                    when others   => ALUBMUX <= '1';
                end case;
        end case;
    end process;

    -- Concurrent Assignments
    UpdReg <= '1' when y_present = WriteBack else '0';

    -- ALU result or memory data (RegWrMUX)
    RegWrMUX <= '0' when (y_present = WriteBack and OpCode = "010111") else '1';

    -- Output FSM state to LEDG (one-hot)
    StateOut <= "00000001" when y_present = StartFetch else
                "00000010" when y_present = LoadIR     else
                "00000100" when y_present = DecodeOp   else
                "00001000" when y_present = CheckBranch else
                "00010000" when y_present = MemAccess  else
                "00100000" when y_present = WriteBack  else
                "00000000";  -- Default

end Behavioral;
