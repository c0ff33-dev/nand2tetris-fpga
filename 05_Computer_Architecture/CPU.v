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
        input [15:0] inM,         // M value input  (M = contents of RAM[A])
        input [15:0] instruction, // Instruction for execution
        input reset,              // Signals whether to restart the current
                                  // program (reset==1) or continue executing
                                  // the current program (reset==0).
        output [15:0] outM,       // M value output
        output writeM,            // Write to M
        output [15:0] addressM,   // Address in data memory (of M) to read
        output [15:0] pc          // address of next instruction
);

    // Put your code here:
    wire [15:0] dout;
    wire ctype;
    wire zr,ng;
    wire jmp;

    // [15] = MSB, [15:13] = opcode
    // 0xxx xxxx xxxx xxxx = A instruction (original, 32k words)
    // 110x xxxx xxxx xxxx = A instruction (new, 56k words)
    // 111x xxxx xxxx xxxx = C instruction (original)
    // 1--x xxxx xxxx xxxx = C instruction (new, same bits after first 3)

    // [12] = A/M bit (0=A, 1=M)
    // [11:6] = comp bits
    // [5:3] = dest bits
    // [2:0] = jump bits

    // Decode instruction type (0=A, 1=C)
    assign ctype = instruction[15] && instruction[14] && instruction[13];

    // Decode writeM (C instruction & dest includes M)
    assign writeM = ctype ? instruction[3] : 1'b0;

    Register regA (
        .clk(clk),
        .in(!ctype ? instruction : outM), // mux: address or ALU output via ctype
        .load(!ctype | instruction[5]), // load if A or dest includes A
        .out(addressM)
    );

    Register regD (
        .clk(clk),
        .in(outM),
        .load(ctype ? instruction[4] : 1'b0), // load if C & dest includes D
        .out(dout)
    );

    ALU alu (
        .x(dout),
        .y(instruction[12] ? inM : addressM), // mux: A or M via a/m bit
        .zx(instruction[11]),
        .nx(instruction[10]),
        .zy(instruction[9]),
        .ny(instruction[8]),
        .f(instruction[7]),
        .no(instruction[6]),
        .out(outM),
        .zr(zr),
        .ng(ng)
    );

    // Decode jump condition (C instruction & jump condition is true)
    // [2]: JLT/JNE/JLE/JMP (ng==1)
    // [1]: JEQ/JGE/JLE/JMP (zr==1)
    // [0]: JGT/JGE/JNE/JMP (ng==0 && zr==0)
    assign jmp = ctype && ((ng && instruction[2]) || (zr && instruction[1]) || (~(ng|zr) && instruction[0]));

    PC pc_reg (
        .clk(clk),
        .in(addressM),
        .load(jmp),
        .inc(!jmp),
        .reset(reset),
        .out(pc)
    );

endmodule
