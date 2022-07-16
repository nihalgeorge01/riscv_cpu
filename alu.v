//                              -*- Mode: Verilog -*-
// Filename        : alu.v
// Description     : Arithmetic and Logic (and shifting) Unit
// Author          : Nihal John George
// 

/* 
    ALU performs an operation denoted by op on 32-bit values in a and b, and stores result in c
    Total 10 ALU operations: 8 normal, 2 subtractions. Supports 19 integer arithmetic ops of RISC V

    ALU Opcode scheme
    4 bits : op[3] = funct7[5] = instr[30] -- 1 for subtract, 0 otherwise. 
            op[2:0] = funct3 = instr[14:12], going from 0 to 7. 

    0000 - ADD, ADDI (and LUI, AUIPC, JAL, JALR, Loads, Stores, NOP, default cases)
    1000 - SUB  (and BEQ, BNE)
    0001 - SLL, SLLI
    0010 - SLT, SLTI    (and BLT, BGE)
    0011 - SLTU, SLTIU  (and BLTU, BGEU)
    0100 - XOR, XORI
    0101 - SRL, SRLI
    1101 - SRA, SRAI
    0110 - OR, ORI
    0111 - AND, ANDI
*/

module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] op,
    output [31:0] out
);
    
    reg [31:0] c;
    
    always @(*) 
    begin
        case(op)
            // Sign extension of immediates to be done by ImmGen / CPU
            
            4'b0000 : c <= a + b; 
            4'b1000 : c <= a - b;
            4'b0001 : c <= a << b[4:0];
            4'b0010 : c <= $signed(a) < $signed(b) ? 1 : 0;
            4'b0011 : c <= a < b ? 1 : 0;
            4'b0100 : c <= a ^ b;
            4'b0101 : c <= a >> b[4:0];
            4'b1101 : c <= $signed(a) >>> b[4:0];
            4'b0110 : c <= a | b;
            4'b0111 : c <= a & b;
            
            default : c <= 0;
        endcase
    end
    
    assign out = c;
endmodule