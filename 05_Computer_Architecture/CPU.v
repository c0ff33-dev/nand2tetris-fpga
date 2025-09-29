/**
 * The Hack CPU (Central Processing unit), consisting of an ALU,
 * two registers named A and D, and a program counter named PC.
 * The CPU is designed to fetch and execute instructions written in 
 * the Hack machine language. In particular, functions as follows:
 * Executes the inputted instruction according to the Hack machine 
 * language specification. The D and A in the language specification
 * refer to CPU-resident registers, while M refers to the external
 * memory location addressed by A, i.e. to Memory[A]. The inM input 
 * holds the value of this location. If the current instruction needs 
 * to write a value to M, the value is placed in outM, the address 
 * of the target location is placed in the addressM output, and the 
 * writeM control bit is asserted. (When writeM==0, any value may 
 * appear in outM). The outM and writeM outputs are combinational: 
 * they are affected instantaneously by the execution of the current 
 * instruction. The addressM and pc outputs are clocked: although they 
 * are affected by the execution of the current instruction, they commit 
 * to their new values only in the next time step. If reset==1 then the 
 * CPU jumps to address 0 (i.e. pc is set to 0 in next time step) rather 
 * than to the address resulting from executing the current instruction. 
 */

`default_nettype none
module CPU(
		input clk,
    	input [15:0] inM,         	// M value input  (M = contents of RAM[A])
    	input [15:0] instruction, 	// Instruction for execution
		input reset,				// Signals whether to re-start the current
                         			// program (reset==1) or continue executing
                         			// the current program (reset==0).

    	output [15:0] outM,			// M value output
    	output writeM,				// Write to M? 
    	output [15:0] addressM,		// Address in data memory (of M) to read
    	output [15:0] pc			// address of next instruction
);

	// TODO: placeholder code from test bench
	reg [15:0] _addressM=0;
	reg [15:0] regD=0;
	reg [15:0] _pc=0;
	reg zx,nx,zy,ny,f,no;
	wire [15:0] out;
	wire [15:0] x,y;
	wire zr,ng;
	assign x = instruction[10]?(instruction[11]?~0:~regD):(instruction[11]?0:regD);
	assign y = instruction[8]?(instruction[9]?~0:~(instruction[12]?inM:_addressM)):(instruction[9]?0:(instruction[12]?inM:_addressM));
	assign out = instruction[6]?(instruction[7]?~(x+y):~(x&y)):(instruction[7]?(x+y):(x&y));
	wire comp;
	wire jmp;
	assign comp = instruction[15] && instruction[14] && instruction[13];
	assign zr = (out==0);
	assign ng = out[15];
	assign jmp = comp && ((ng&&instruction[2])||(zr&&instruction[1])||(~(ng|zr)&&instruction[0]));
	always @(posedge clk) begin
		_addressM <= comp?(instruction[5]?out:_addressM) : instruction;
		regD <= comp?(instruction[4]?out:regD) : regD;
		_pc <= reset?0 : (jmp?_addressM:_pc+1);
	end

	assign writeM = comp?instruction[3]:0;
	assign pc = _pc;
	assign addressM = _addressM;

endmodule
