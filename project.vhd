-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Final Project PART III
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------
-- FILE: Project_ENG304FINAL.vhd
--   This is the top-level project file for week one.
-- DESCRIPTION:
--  This file implements the top-level design for PART I.
--    - It instantiates the Program Counter (PC) and Instruction Register (IR)
--      using a 32-bit register with update.
--    - It instantiates the RAM module to fetch instructions.
--    - It drives the HEX displays with the state of the IR.
-- COURSE: Engineering 304
-----------------------------------------------------------------------------
-- MODIFICATION HISTORY:  
-- Revision 1.0  4/25/22  Prof. Michmerhuizen
-- File as supplied by the professor.
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.sevenSeg_pkg.ALL;

ENTITY Project IS
   PORT (
      KEY       : IN  std_logic_vector(3 downto 0);
      SW        : IN  std_logic_vector(15 downto 0);
      --Clock     : IN  std_logic;      -- renamed from CLK
      --Reset_n   : IN  std_logic;      -- renamed from RSTn
		LEDG		: OUT std_logic_vector(7 downto 0);  
      HEX7      : OUT std_logic_vector(6 downto 0);
      HEX6      : OUT std_logic_vector(6 downto 0);
      HEX5      : OUT std_logic_vector(6 downto 0);
      HEX4      : OUT std_logic_vector(6 downto 0);
      HEX3      : OUT std_logic_vector(6 downto 0);
      HEX2      : OUT std_logic_vector(6 downto 0);
      HEX1      : OUT std_logic_vector(6 downto 0);
      HEX0      : OUT std_logic_vector(6 downto 0)
   );
END Project;

ARCHITECTURE ProjectBehavior OF Project IS

   -----------------------------------------------------------------------------
   -- Existing PART A Signals
   -----------------------------------------------------------------------------
   signal Clock : std_logic;   
   signal Reset_n : std_logic;	
	
	signal PCUpd         : std_logic;
   signal IRUpd         : std_logic;
   signal PC_Input      : std_logic_vector(31 downto 0);
   signal IR_Input      : std_logic_vector(31 downto 0);
   signal PC_Out        : std_logic_vector(31 downto 0);
   signal IR_Out        : std_logic_vector(31 downto 0);
   signal Mem_RdDt0     : std_logic_vector(31 downto 0);
   signal PC_word_addr  : std_logic_vector(10 downto 0);
   
   -----------------------------------------------------------------------------
   -- New Signals for PART B Step 6: Decoder, Sign Ext., & Register File
   -----------------------------------------------------------------------------
   -- Decoder outputs (from DecoderFinal.vhd)
   signal Decoder_RegRdA      : std_logic_vector(4 downto 0);
   signal Decoder_RegRdB      : std_logic_vector(4 downto 0);
   signal Decoder_RegWr       : std_logic_vector(4 downto 0);
   signal Decoder_ALUOp       : std_logic_vector(3 downto 0);
   signal Imm_16_from_decoder : std_logic_vector(15 downto 0);
   
   -- Signal for the extended immediate value (output of Sign Extension module)
   signal ImmExt              : std_logic_vector(31 downto 0);
   -- Control for whether to sign extend ('1') or zero extend ('0'); defaulting here to sign extension.
   signal ExtSel              : std_logic := '1';
   
   -- Register file interface signals
   signal RegFile_Upd         : std_logic := '0';   -- Update control from the controller, for example.
   signal ALU_Result          : std_logic_vector(31 downto 0) := (others => '0');  -- placeholder for ALU result.
   signal RegAData            : std_logic_vector(31 downto 0);
   signal RegBData            : std_logic_vector(31 downto 0);
   
   
  

   --week 2 part b
   signal ALUInB    : std_logic_vector(31 downto 0); -- output of ALUInBMux
   signal ALUOut : std_logic_vector(31 downto 0);
   signal ALUZero : std_logic;
   signal ShftAmt   : std_logic_vector(4 downto 0); -- e.g., from IR_Out

   signal OpCode        : std_logic_vector(1 downto 0);
   signal RegWrMUX      : std_logic;
   signal ALUBMUX       : std_logic;
   signal BrnchTaken    : std_logic;
   signal WriteDataMux_WrData : std_logic_vector (31 downto 0); 
   signal Mem_Update : std_logic;
   signal Mem_RdDt1 : std_logic_vector(31 downto 0);
   signal prefix: std_logic_vector(15 downto 0);
	
	--week 3 
	signal WrDt0       : std_logic_vector(31 downto 0) := (others => '0');  -- Unused write port
   signal WrEnable0   : std_logic := '0';                                  -- Unused write enable
   
   -- Display multiplexer signals
   signal display_select : std_logic_vector(2 downto 0);
   signal display_value  : std_logic_vector(31 downto 0);
   
   -- Branch adder output (for display)
   signal branch_adder_out : std_logic_vector(31 downto 0);

   -- Controller state signals for LEDG outputs
   signal ctrl_state : std_logic_vector(7 downto 0);


   -----------------------------------------------------------------------------
   -- Component Declarations
   -----------------------------------------------------------------------------
   COMPONENT RegWithUpdate IS
      PORT (
         CLK   : IN  std_logic;
         RSTn  : IN  std_logic;
         Upd   : IN  std_logic;
         D     : IN  std_logic_vector(31 downto 0);
         Q     : OUT std_logic_vector(31 downto 0)
      );
   END COMPONENT;

  COMPONENT MemoryBlock IS
      PORT (
         clock       : IN  std_logic;
         Addr0       : IN  std_logic_vector(10 downto 0);
         Addr1       : IN  std_logic_vector(10 downto 0);
         WrDt0       : IN  std_logic_vector(31 downto 0);
         WrEnable0   : IN  std_logic;
         WrDt1       : IN  std_logic_vector(31 downto 0);
         WrEnable1   : IN  std_logic;
         RdDt0       : OUT std_logic_vector(31 downto 0);
         RdDt1       : OUT std_logic_vector(31 downto 0)
      );
   END COMPONENT;

   -- Decoder from DecoderFinal.vhd
   COMPONENT Decoder IS
      PORT (
         Instr  : IN  std_logic_vector(31 downto 0);
         RegRdA : OUT std_logic_vector(4 downto 0);
         RegRdB : OUT std_logic_vector(4 downto 0);
         Imm16  : OUT std_logic_vector(15 downto 0);
         ALUOp  : OUT std_logic_vector(3 downto 0);
         RegWr  : OUT std_logic_vector(4 downto 0)
      );
   END COMPONENT;
   
   -- Register file (GenRegisters.vhd)
   COMPONENT GenRegisters IS
      PORT (
         Clock       : IN std_logic;
         Reset_n     : IN std_logic;
         UpdRegister : IN std_logic;
         WrAddr      : IN std_logic_vector(4 downto 0);
         WrData      : IN std_logic_vector(31 downto 0);
         RegAAddr    : IN std_logic_vector(4 downto 0);
         RegBAddr    : IN std_logic_vector(4 downto 0);
         RegA        : OUT std_logic_vector(31 downto 0);
         RegB        : OUT std_logic_vector(31 downto 0)
      );
   END COMPONENT;
   
Component ArethmeticLogicUnit is
	port (
		InA 	: in std_logic_vector(31 downto 0);
		InB 	: in std_logic_vector(31 downto 0);
		OpCode 	: in std_logic_vector(3 downto 0);
		Shift 	: in std_logic_vector(4 downto 0);
		ALUOut 	: out std_logic_vector(31 downto 0);
		ALUZero	: out std_logic
		);
	end component;

Component Controller is
    Port (
        Clk         : in  std_logic;
        Reset       : in  std_logic;
		ALUZero     : in  std_logic;
        --OpCode      : in  std_logic_vector(5 downto 0);
		
		Instr       :  std_logic_vector(31 downto 0);
		
        UpdMem      : out std_logic;
        UpdPC       : out std_logic;
        UpdIR       : out std_logic;
        UpdReg      : out std_logic;
        RegWrMUX    : out std_logic;
        ALUBMUX     : out std_logic;
        BrnchTaken  : out std_logic;
		  StateOut    : OUT std_logic_vector(7 downto 0)
    );
end component;

BEGIN
   -----------------------------------------------------------------------------
   -- Week 3 
   -----------------------------------------------------------------------------
   Clock <= KEY(3);
   Reset_n <= KEY(0);
	
	 display_select <= SW(2 downto 0);
	 branch_adder_out <= std_logic_vector(unsigned(PC_Out) + 4 + unsigned(ImmExt));

	 -----------------------------------------------------------------------------
   -- Existing Instantiations from PART A
   -----------------------------------------------------------------------------
	PC_Reg : RegWithUpdate
      PORT MAP (
         CLK   =>	Clock,
         RSTn  => Reset_n,
         Upd   => PCUpd,
         D     => PC_Input,
         Q     => PC_Out               
      );

   IR_Reg : RegWithUpdate
      PORT MAP (
         CLK   => Clock,
         RSTn  => Reset_n,
         Upd   => IRUpd,
         D     => IR_Input,
         Q     => IR_Out
      );

   MemoryBlockInstance : MemoryBlock
      PORT MAP (
         clock         => Clock,
         Addr0       => PC_word_addr, -- instruction fetch address
         Addr1       => ALUOut(10 downto 0),  -- grab last 11 bits  
         WrDt0       => WrDt0,             -- Unused write port
         WrEnable0   => WrEnable0,         -- Unused write enable
			WrDt1       => RegBData,
         WrEnable1   => Mem_Update,
         RdDt0       => Mem_RdDt0,
         RdDt1       => Mem_RdDt1
      );
	  
	ALU : ArethmeticLogicUnit
	port map (
		InA     => RegAData,
		InB     => ALUInB,
		OpCode  => Decoder_ALUOp,
		Shift   => ShftAmt,
		ALUOut  => ALUOut,
		ALUZero => ALUZero
	);
	
	ControllerUnit: Controller
    PORT MAP (
        Clk         => Clock,
        Reset       => Reset_n,
      --  OpCode      => IR_Out(5 downto 0), --edited
        ALUZero     => ALUZero,
        UpdMem      => Mem_Update,
        Instr       => IR_Out,
        UpdPC       => PCUpd,
        UpdIR       => IRUpd,
        UpdReg      => RegFile_Upd,
        RegWrMUX    => RegWrMUX,
        ALUBMUX     => ALUBMUX,
        BrnchTaken  => BrnchTaken,
		  StateOut => ctrl_state
    );



   -----------------------------------------------------------------------------
   -- Additional Logic for PART B Step 6
   -----------------------------------------------------------------------------
   -- Instantiate the Decoder module (from DecoderFinal.vhd)
   DecoderInstance: Decoder
     PORT MAP (
         Instr  => IR_Out,
         RegRdA => Decoder_RegRdA,
         RegRdB => Decoder_RegRdB,
         Imm16  => Imm_16_from_decoder,
         ALUOp  => Decoder_ALUOp,
         RegWr  => Decoder_RegWr
     );

   -- Sign Extension Module Implementation as a Process:
   -- If ExtSel = '1', then sign-extend (i.e., replicate the MSB of Imm16); if '0', then zero-extend.
   
   SignExt_proc: process(Imm_16_from_decoder, ExtSel, OpCode)
     -- signal prefix: std_logic_vector(15 downto 0);
   begin
       if (ExtSel = '1') then
         prefix <= (others => Imm_16_from_decoder(15));
      -- elsif (ExtSel = '1' and OpCode = x"14") then
       --  prefix <= Imm_16_from_decoder(10 downto 0);
      -- elsif (ExtSel = '1' and OpCode = x"6") then
      --   prefix <= (others => Imm_16_from_decoder(15));
      --  elsif (ExtSel = '1' and OpCode = x"1e") then
      --   prefix <= (others => Imm_16_from_decoder(15));
       else
         prefix <= (others => '0');
      end if;
   end process;
   ImmExt <= prefix & Imm_16_from_decoder;
   ExtSel <= '0' when Decoder_ALUOp = x"6" else '1';
      ShftAmt <= IR_Out(10 downto 6); 
   
   --  adder Module Implementation for branching instructions
   -- take output of the PC register and add 0x04, then add signed extended immediate16 decoder value
   adder: process (PC_Out, BrnchTaken, ImmExt)
	--	signal ImmExt32  : signed(31 downto 0);
		BEGIN
			if (BrnchTaken = '1') then
				PC_Input <= std_logic_vector(unsigned(PC_Out) + 4 + unsigned(ImmExt));
			else
				PC_Input <= std_logic_vector(unsigned(PC_Out) + 4);
			end if;
		end process;


--write data Mux module Implementation
WriteDataMux: Process (ALUOut, RegWrMux, WriteDataMux_WrData)
	BEGIN
		if (RegWrMux = '1') then
			WriteDataMux_WrData <= ALUOut;
		else
		WriteDataMux_WrData <= Mem_RdDt1; 
		end if;
	end process;
	
-- ALU B in mux moduule Implementation	
ALUBInMux: process (ALUBMux, ImmExt, RegBData)
begin
	if (ALUBMux = '1') then
		ALUInB <= ImmExt;  -- ImmExt32 is signed, cast to std_logic_vector
	else
		ALUInB <= RegBData;
	end if;
end process;
	
   -- Instantiate the Register File using GenRegisters.vhd
   RegisterFileInstance: GenRegisters
     PORT MAP (
         Clock       => Clock,
         Reset_n     => Reset_n,
         UpdRegister => RegFile_Upd,            -- from the controller (placeholder for now)
         WrAddr      => Decoder_RegWr,          -- destination register from decoder
         WrData      => WriteDataMux_WrData,             -- ALU output (placeholder signal)
         RegAAddr    => Decoder_RegRdA,         -- source register A from decoder
         RegBAddr    => Decoder_RegRdB,         -- source register B from decoder
         RegA        => RegAData,               -- register file output for port A
         RegB        => RegBData                -- register file output for port B
     );

   -----------------------------------------------------------------------------
   -- Additional Signal Assignments and Existing Logic
   -----------------------------------------------------------------------------
   --PC_Input     <= std_logic_vector(unsigned(PC_Out) + 4);
   IR_Input     <= Mem_RdDt0;
   PC_word_addr <= PC_Out(12 downto 2);  -- Convert byte address to word address



	-----------------------------------------------------------------------------
   -- Display Mux
   -----------------------------------------------------------------------------
	display_mux: process(display_select, PC_Out, branch_adder_out, ALUOut, IR_Out, 
                        Mem_RdDt0, Mem_RdDt1, RegAData, RegBData)
   begin
      case display_select is
         when "000" => display_value <= PC_Out;           -- Program Counter
         when "001" => display_value <= branch_adder_out; -- Branch Adder output
         when "010" => display_value <= ALUOut;           -- ALU output
         when "011" => display_value <= IR_Out;           -- Instruction Register
         when "100" => display_value <= Mem_RdDt0;        -- Memory Output 0
         when "101" => display_value <= Mem_RdDt1;        -- Memory Output 1
         when "110" => display_value <= RegAData;         -- Register A Output
         when "111" => display_value <= RegBData;         -- Register B Output
         when others => display_value <= IR_Out;          -- Default to IR
      end case;
   end process;

	  -- Drive HEX displays with selected display value
   HEX7 <= convert_to_7seg(display_value(31 downto 28));
   HEX6 <= convert_to_7seg(display_value(27 downto 24));
   HEX5 <= convert_to_7seg(display_value(23 downto 20));
   HEX4 <= convert_to_7seg(display_value(19 downto 16));
   HEX3 <= convert_to_7seg(display_value(15 downto 12));
   HEX2 <= convert_to_7seg(display_value(11 downto 8));
   HEX1 <= convert_to_7seg(display_value(7 downto 4));
   HEX0 <= convert_to_7seg(display_value(3 downto 0));

   -- Output controller state to green LEDs
   LEDG <= ctrl_state;
	
	IR_Input     <= Mem_RdDt0;
   PC_word_addr <= PC_Out(12 downto 2);  -- Convert byte address to word address

END ProjectBehavior;


