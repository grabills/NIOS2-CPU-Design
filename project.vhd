-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Finak Project PART I 
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
      Clock     : IN  std_logic;      -- renamed from CLK
      Reset_n   : IN  std_logic;      -- renamed from RSTn
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
   signal PCUpd         : std_logic;
   signal IRUpd         : std_logic;
   signal PC_Input      : std_logic_vector(31 downto 0);
   signal IR_Input      : std_logic_vector(31 downto 0);
   signal PC_Out        : std_logic_vector(31 downto 0);
   signal IR_Out        : std_logic_vector(31 downto 0);
   signal Mem_RdDt0     : std_logic_vector(31 downto 0);
   signal PC_word_addr  : std_logic_vector(10 downto 0);
   
   -----------------------------------------C:/Users/ssg6/Downloads/CorrectThings/Project_ENG304FINAL.vhd------------------------------------
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

   COMPONENT MemoryModule IS
      PORT (
         CLK         : IN  std_logic;
         Addr0       : IN  std_logic_vector(10 downto 0);
         Addr1       : IN  std_logic_vector(10 downto 0);
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
        --OpCode      : in  std_logic_vector(1 downto 0);
		
		Instr       :  std_logic_vector(31 downto 0);
		
        UpdMem      : out std_logic;
        UpdPC       : out std_logic;
        UpdIR       : out std_logic;
        UpdReg      : out std_logic;
        RegWrMUX    : out std_logic;
        ALUBMUX     : out std_logic;
        BrnchTaken  : out std_logic
    );
end component;

BEGIN
   -----------------------------------------------------------------------------
   -- Existing Instantiations from PART A
   -----------------------------------------------------------------------------
   PC_Reg : RegWithUpdate
      PORT MAP (
         CLK   => Clock,
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

   MemoryBlockInstance : MemoryModule
      PORT MAP (
         CLK         => Clock,
         Addr0       => PC_word_addr, -- instruction fetch address
         Addr1       => ALUOut(10 downto 0),  -- grab last 11 bits  
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
        --OpCode      => ALUOp,
        ALUZero     => ALUZero,
        UpdMem      => Mem_Update,
        Instr       => IR_Out,
        UpdPC       => PCUpd,
        UpdIR       => IRUpd,
        UpdReg      => RegFile_Upd,
        RegWrMUX    => RegWrMUX,
        ALUBMUX     => ALUBMUX,
        BrnchTaken  => BrnchTaken
    );

   -- Drive HEX displays with IR register value (using SevenSeg_pkg)
   HEX7 <= convert_to_7seg(IR_Out(31 downto 28));
   HEX6 <= convert_to_7seg(IR_Out(27 downto 24));
   HEX5 <= convert_to_7seg(IR_Out(23 downto 20));
   HEX4 <= convert_to_7seg(IR_Out(19 downto 16));
   HEX3 <= convert_to_7seg(IR_Out(15 downto 12));
   HEX2 <= convert_to_7seg(IR_Out(11 downto 8));
   HEX1 <= convert_to_7seg(IR_Out(7 downto 4));
   HEX0 <= convert_to_7seg(IR_Out(3 downto 0));

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
      variable prefix: std_logic_vector(15 downto 0);
   begin
       if (ExtSel = '1') then
         prefix := (others => Imm_16_from_decoder(15));
       end if;
       if (ExtSel = '1' and OpCode = x"14") then
         prefix := Imm_16_from_decoder(10 downto 0);
       else
         prefix := (others => '0');
      end if;
      ImmExt <= prefix & Imm_16_from_decoder;
   end process;
   
      ShftAmt <= IR_Out(10 downto 6); 
   
   --  adder Module Implementation for branching instructions
   -- take output of the PC register and add 0x04, then add signed extended immediate16 decoder value
   --queestionable
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
		WriteDataMux_WrData <= Mem_RdDt1; --since we can't use RdDt1 yet
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

   -- Simulation forces for update signals (if required)
   --PCUpd <= '1';
   --IRUpd <= '1';

END ProjectBehavior;


