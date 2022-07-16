//                              -*- Mode: Verilog -*-
// Filename        : immgen.v
// Description     : Immediate Generator
// Author          : Nihal John George
// 

module immgen(
    input [31:0] instr,
    output [31:0] imm
);
    
    reg [31:0] c;

    always @(*)
    begin
        case(instr[6:0])
            7'b0110111,     // Case 1: LUI,  
            7'b0010111:     // AUIPC
                c           <= {instr[31:12], 12'b0};  
            
            7'b1101111:     // Case 2: JAL
                c           <= $signed({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
            
            7'b1100111,     // Case 3: JALR,
            7'b0010011,     // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            7'b0000011:     // LB, LH, LW, LBU, LHU
                c           <= $signed(instr[31:20]);
            
            // Don't care about masking leading 7 bits of 12 bit imms 
            // for SLLI, SRLI, SRAI since ALU considers only low 5 bits as shamt

            7'b0100011:     // Case 4: SB, SH, SW
                c           <= $signed({instr[31:25], instr[11:7]});
            
            7'b1100011:     // Case 5: BEQ, BNE, BLT, BGE, BLTU, BGEU 
                c           <= $signed({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});

            default:
                c           <= 0;
        endcase
    end

    assign imm = c;
endmodule