-----------------------------------------------------------------------------
-- TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
-- DATE: 04/22/25
-- PURPOSE: Finak Project PART I 
-- Professor: M. Michmerhuizen
-----------------------------------------------------------------------------
-- FILE: MemoryModule.vhd
--   This file contains VHDL that implements thirty two 32-bit registers
-- DESCRIPTION:
--   The memory module has two read ports and one write port.  The input
--   addresses are clocked in and the data output is updated. To write to 
--   the memory module, port B must be used and we_b must be asserted high
--   during a clock edge.  The memory is not reset with a global reset action.
-- COURSE: 		Engineering 304
-----------------------------------------------------------------------------
-- MODIFICATION HISTORY:  
-- Revision 1.0  File as supplied by the professor.
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MemoryModule is
	port 
	(	
    CLK		    : in std_logic;
    Addr0	    : in std_logic_vector(10 downto 0);
    Addr1	    : in std_logic_vector(10 downto 0);
    WrDt1	    : in std_logic_vector(31 downto 0);
    WrEnable1	: in std_logic := '0';
    RdDt0		  : out std_logic_vector(31 downto 0);
    RdDt1		  : out std_logic_vector(31 downto 0)
	);
	
end MemoryModule;

architecture rtl of MemoryModule is
	
	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector(31 downto 0);
	type memory_t is array(0 to 2047) of word_t;
	
	-- Declare the RAM
	signal ram : memory_t;

begin

	-- Port A
	process(CLK) -- no reset state for RAM cells
	begin
		if(rising_edge(CLK)) then 
			RdDt0 <= ram(conv_integer(Addr0));
		end if;
	end process;
	
	-- Port B
	process(CLK)
	begin  -- Note that RdDt1 will not take on the new value
         -- until the following clock edge.
		if(rising_edge(CLK)) then
			if(WrEnable1 = '1') then
				ram(conv_integer(Addr1)) <= WrDt1;
			end if;
			RdDt1 <= ram(conv_integer(Addr1));
		end if;
	end process;
end rtl;
