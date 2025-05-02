# TEAM: Samuel Knox, Piranavan Maha, Sebastian Grabill, Onahi Ida-Michaels
# DATE: 04/22/25
# PURPOSE: Final Project PART I 
# Professor: M. Michmerhuizen
#
vsim -gui work.project
#
# Set up wave window.  (Comment lines begin with a hash mark.)
# You may find it handy to preface bus signals in this section with "-radix hex"
#	so that signal values display in hex format, rather than binary
#
add wave -position insertpoint  \
sim:/project/Clock \
sim:/project/Reset_n \
sim:/project/PCUpd \
sim:/project/IRUpd \
sim:/project/Mem_Update \
sim:/project/ALUZero \
sim:/project/RegWrMUX \
sim:/project/ALUBMUX \
sim:/project/BrnchTaken \
sim:/project/Decoder_RegWr \
-radix hex sim:/project/RegBData \
-radix hex sim:/project/ALUInB \
-radix hex sim:/project/IR_Out \
-radix hex sim:/project/PC_Out \
-radix hex sim:/project/RegFile_Upd \
-radix hex sim:/project/RegAData \
-radix hex sim:/project/WriteDataMux_WrData \
-radix hex sim:/project/ImmExt \
-radix hex sim:/project/DecoderInstance/RegRDA \
-radix hex sim:/project/DecoderInstance/ALUOp \
-radix hex sim:/project/ALU/OpCode \
-radix hex sim:/project/ALU/Shift \
-radix hex sim:/project/ALUOut \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(16) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(12) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(6) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(5) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(4) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(3) \
-radix hex sim:/project/RegisterFileInstance/AllRegisters(2) \
sim:/project/ControllerUnit/y_present \
sim:/project/ControllerUnit/y_next \
-radix hex sim:/project/ControllerUnit/OpCode 


#
#	For the memory load command, Ram_Contents_Short.mem is the name of your memory contents file.
#	/Project/MemoryBlockInstance is the name of the component instantiated within your design.
#	The command below assumes your top-level entity is named "Project" and
#		the memory block component is named "MemoryBlockInstance"
#	That is, you have a line like this in your VHDL file:
#		MemoryBlockInstance : COMPONENT MemoryModule
#
mem load -i Ram_Contents.mem /Project/MemoryBlockInstance
#
# Forces
#	Add any additional forces you need here
#
force Clock 0 0ns, 1 20ns -r 40ns 
force Reset_n 0 0ns, 1 15ns
#
#	Replace <TBD> with a number
run 3.2 us


