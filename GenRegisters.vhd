-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Finak Project PART I 
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------
-- FILE: GenRegisters.vhd
--   This file contains VHDL that implements thirty two 32-bit registers
-- DESCRIPTION:
--   The register file has two read ports and one write port.  The write
--   port if clocked; the read ports are not clocked.  Reg0 is not 
--   writeable; it is always going to be 0x00.  UpdRegister is used to
--   control when a register write action takes place.
-- COURSE: 		Engineering 304 - Spring 2018
-- DESIGN TOOL: 	Fill_In
-----------------------------------------------------------------------------
-- MODIFICATION HISTORY:  
-- Revision 1.0  3/27/18  2:00 PM  Prof. Brouwer
-- File as supplied by the professor.
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY GenRegisters IS
  PORT (
	Clock 		: IN std_logic;
	Reset_n 	: IN std_logic;
	UpdRegister : IN std_logic;
	WrAddr 		: IN std_logic_vector(4 downto 0);
	WrData 		: IN std_logic_vector(31 downto 0);
	RegAAddr 	: IN std_logic_vector(4 downto 0);
	RegBAddr 	: IN std_logic_vector(4 downto 0);
	RegA 		: OUT std_logic_vector(31 downto 0);
	RegB 		: OUT std_logic_vector(31 downto 0)
  );
END GenRegisters;

-----------------------------------------------------------------------------
-- ARCHITECTURE: behav
-- This architecture is implemented with behavioral VHDL
-----------------------------------------------------------------------------
ARCHITECTURE behav OF GenRegisters IS
  subtype t_dim1 is std_logic_vector(31 downto 0);  -- represents one register
  type AllReg is array(31 downto 0) of t_dim1;  -- represents 32 registers
  signal AllRegisters : AllReg;  -- declare the signal
BEGIN
  RegA <= AllRegisters(CONV_INTEGER(RegAAddr));
  RegB <= AllRegisters(CONV_INTEGER(RegBAddr));
  
  PROCESS (Clock, Reset_n) is
  begin
    if (Reset_n = '0') then
      AllRegisters(0) <= (others => '0');
      AllRegisters(1) <= (others => '0');
      AllRegisters(2) <= x"456789ab";  -- give them a non-zero value for testing
      AllRegisters(3) <= x"13579bdf";
      AllRegisters(4) <= x"02468ace";
      AllRegisters(5) <= (others => '0');
      AllRegisters(6) <= (others => '0');
      AllRegisters(7) <= (others => '0');
      AllRegisters(8) <= (others => '0');
      AllRegisters(9) <= (others => '0');
      AllRegisters(10) <= (others => '0');
      AllRegisters(11) <= (others => '0');
      AllRegisters(12) <= (others => '0');
      AllRegisters(13) <= (others => '0');
      AllRegisters(14) <= (others => '0');
      AllRegisters(15) <= (others => '0');
      AllRegisters(16) <= (others => '0');
      AllRegisters(17) <= (others => '0');
      AllRegisters(18) <= (others => '0');
      AllRegisters(19) <= (others => '0');
      AllRegisters(20) <= (others => '0');
      AllRegisters(21) <= (others => '0');
      AllRegisters(22) <= (others => '0');
      AllRegisters(23) <= (others => '0');
      AllRegisters(24) <= (others => '0');
      AllRegisters(25) <= (others => '0');
      AllRegisters(26) <= (others => '0');
      AllRegisters(27) <= (others => '0');
      AllRegisters(28) <= (others => '0');
      AllRegisters(29) <= (others => '0');
      AllRegisters(30) <= (others => '0');
      AllRegisters(31) <= (others => '0');
    elsif (Clock'event and Clock = '1') then
      if ((UpdRegister = '1') and (WrAddr /= "00000")) then
        -- don't update register 0 (r0) since it should always be 0
        AllRegisters(CONV_INTEGER(WrAddr)) <= WrData;
      end if;
    end if;
  end process;
end architecture;
