-----------------------------------------------------------------------------
-- GROUP: Samuel Knox, Seebastian Grabill, Piranavan Maha, Onahi Ida-Michaels
-- DATE: 04/22/25
-- CLASS: ENG304L 
-- Purpose: Week 1 of Final Project
-----------------------------------------------------------------------------
-- FILE: 32bitRegWithUpdate.vhd
--  This file contains VHDL that implements a 32-bit register with an update input
-- DESCRIPTION:
--  This file implements a 32-bit register that maintains its current value
--	unless the Upd signal is asserted, in which case the "D" input is loaded.
--	It is based on code developed by Prof. R. Brouwer, Calvin University.
-- COURSE: 		Engineering 304
-----------------------------------------------------------------------------
-- MODIFICATION HISTORY:  
-- Revision 1.0  4/25/22  Prof. Michmerhuizen
-- File as supplied by the professor.
-----------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY RegWithUpdate IS
    PORT (
        CLK     :   IN std_logic;
        RSTn    :   IN std_logic;
        Upd     :   IN std_logic;
        D       :   IN std_logic_vector(31 downto 0);
        Q       :   OUT std_logic_vector(31 downto 0)
  );
END RegWithUpdate;

-----------------------------------------------------------------------------
-- ARCHITECTURE: Reg
-- This architecture implements a 32-bit register that holds its value unless
-- the Upd signal is asserted, in which case the input D is loaded at the rising
-- edge of CLK.
-----------------------------------------------------------------------------
ARCHITECTURE Reg OF RegWithUpdate IS
BEGIN
    PROCESS (CLK, RSTn)
    BEGIN
        if (RSTn = '0') then
            Q <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (Upd = '1') then
                Q <= D;
            -- Else: Q remains unchanged; no assignment needed
            end if;
        end if;
    end PROCESS;
END architecture Reg;


