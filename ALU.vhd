LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

entity ArethmeticLogicUnit is
	port (
		InA 		: in std_logic_vector(31 downto 0);
		InB 		: in std_logic_vector(31 downto 0);
		OpCode 	: in std_logic_vector(3 downto 0);
		Shift 	: in std_logic_vector(4 downto 0);
		ALUOut 	: out std_logic_vector(31 downto 0);
		ALUZero	: out std_logic
		);
	end ArethmeticLogicUnit;
	
architecture ALUBehavior of ArethmeticLogicUnit is

	signal ALUSig : std_logic_vector(31 downto 0);

begin
	process (InA, InB, OpCode, Shift)
	  begin
		
		case OpCode is			
			when x"1" =>  --add
                ALUSig <= InA + InB;
			
			when x"2" => --sub
				        ALUSig <= InA - InB;
				
			when x"3" => --or
                ALUSig <= InA OR InB;
                
			when x"4" => --nor
                ALUSig <= NOT (InA OR InB);

			when x"5" => --and
                ALUSig <= InA AND InB;

			when x"6" => --xor
                ALUSig <= InA XOR InB;

			when x"7" => --srli (shift left)
				ALUSig(31 downto CONV_INTEGER(Shift)) <= InA((31 - CONV_INTEGER(Shift)) downto 0);
				ALUSig((CONV_INTEGER(Shift) - 1) downto 0) <= (others => '0');
              

			when x"8" => --srli (shift right)
		    ALUSig(31 - Conv_Integer(Shift) downto 0) <= InA(31 downto Conv_Integer(Shift));
				ALUSig(31 downto 32 - Conv_Integer(Shift)) <= (others => '0');
				
      when x"9" => --orhi
            ALUSig <= InA or (InB(15 downto 0) & x"0000"); 

        
			when others => --invalid instructions
				ALUSig <= (others => '0');
		end case;
	end process;
	
	ALUOut <= ALUSig;
	ALUZero <= '1' WHEN ALUSig = X"00000000" ELSE '0';
	
end ALUBehavior;