//                              -*- Mode: Verilog -*-
// Filename        : control.v
// Description     : Main Control Unit
// Author          : Nihal John George
// 

module control (
    input [31:0] instr,
    input [31:0] ALU_out,     // ALU Output for setting branch target and load value slicing
    input reset,                // Set write signals to 0 if reset is 1
    
    output [2:0] B_Target,        // onehot amongst 3 - (100) PC+4 (separate adder), 
                            //                    (010) PC+imm (separate adder), 
                            //                    (001) rv1+imm (from ALU, for JALR)
                            
    //output MemRead,         // not needed
    output MemToReg,        // 1 if DMEM output goes to rd, 0 if ALU output goes to rd
    output [3:0] ALUOp,     // 4 bit code deciding ALU operation
    output [3:0] dwe,       // 4 bit code decidng which among 4 1-byte banks of DMEM will be written   
    output RegWrite,        // 1 if regfile should be written to, 0 if not

    output [2:0] ALU_rv1,         // onehot amongst 3 - 100 (rv1), 010 (0), 001 (PC)
    output [2:0] ALU_rv2         // onehot amongst 3 - 100 (rv2), 010 (Imm), 001 (4)
                            // can achieve the following 7 ops which write to DMEM or rd only
                            // Arith(rv1, rv2)
                            // Arith(rv1, imm)
                            // rv1 + imm for L, S
                            // 0 + imm for LUI
                            // PC + imm for AUIPC
                            // PC + 4 for JAL, JALR
                            // Compare(rv1, rv2) for B
                            //
                            // Useless - rv1 + 4, PC + rv2, 0 + rv2, 0 + 4

);
    reg [2:0] B_Target_r, ALU_rv1_r, ALU_rv2_r;
    reg [3:0] ALUOp_r, dwe_r;
    reg RegWrite_r, MemToReg_r;

    assign B_Target     = B_Target_r;
    assign ALU_rv1      = ALU_rv1_r;
    assign ALU_rv2      = ALU_rv2_r;
    assign ALUOp        = ALUOp_r;
    assign dwe          = dwe_r;
    assign RegWrite     = RegWrite_r;
    assign MemToReg     = MemToReg_r;

    always @(*)
    begin
        
        case(instr[6:2]) // last 2 bits always 11
            
            5'b01101:       // LUI                          // DONE
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALUOp_r         <= 4'b0000;                     // ADDI 0 + imm
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b010;                      // 0
                ALU_rv2_r       <= 3'b010;                      // imm
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0); // Do not write if dest = x0
            end   
            
            5'b00101:       // AUIPC
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALUOp_r         <= 4'b0000;                     // ADDI PC+imm
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b001;                      // PC
                ALU_rv2_r       <= 3'b010;                      // imm
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
            end
            
            5'b11011:       // JAL
            begin
                B_Target_r      <= 3'b010;                      // PC+imm
                MemToReg_r      <= 0;
                ALUOp_r         <= 4'b0000;                     // ADDI PC+4
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b001;                      // PC
                ALU_rv2_r       <= 3'b001;                      // 4
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
            end
            
            5'b11001:       // JALR
            begin
                B_Target_r      <= 3'b001;                      // rv1+imm (done through separate adder)
                MemToReg_r      <= 0;
                ALUOp_r         <= 4'b0000;                     // ADDI PC+4
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b001;                      // PC
                ALU_rv2_r       <= 3'b001;                      // 4
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
            end
            
            5'b11000:       // Branches (instr starting with B)
            begin
                MemToReg_r      <= 0;
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b100;                      // rv2
                RegWrite_r      <= 0;
                
                case(instr[14:12])                          // if condition true, branch to PC+imm, else PC+4
                    3'b000 :
                    begin 
                        ALUOp_r     = 4'b1000;                    // BEQ using SUBI
                        B_Target_r  = ALU_out == 32'b0 ? 3'b010 : 3'b100;
                    end

                    3'b001 :
                    begin 
                        ALUOp_r     = 4'b1000;                    // BNE using SUBI
                        B_Target_r  = ALU_out != 32'b0 ? 3'b010 : 3'b100;
                    end

                    3'b100 : 
                    begin
                        ALUOp_r     = 4'b0010;                    // BLT using SLT
                        B_Target_r  = ALU_out[0] == 1 ? 3'b010 : 3'b100;
                    end

                    3'b101 : 
                    begin
                        ALUOp_r     = 4'b0010;                    // BGE using SLT
                        B_Target_r  = ALU_out[0] == 0 ? 3'b010 : 3'b100;
                    end
                    
                    3'b110 : 
                    begin
                        ALUOp_r     = 4'b0011;                    // BLTU using SLTU
                        B_Target_r  = ALU_out[0] == 1 ? 3'b010 : 3'b100;
                    end
                    
                    3'b111 : 
                    begin
                        ALUOp_r     = 4'b0011;                    // BGEU using SLTU
                        B_Target_r  = ALU_out[0] == 0 ? 3'b010 : 3'b100;
                    end

                    default :                                     // illegal
                    begin
                        ALUOp_r     = 4'b0000;                    // ADDI but don't care
                        B_Target_r  = 3'b100;                     // PC+4
                    end
                endcase

            end
            
            5'b00000:       // Loads                        
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 1;                           // route DMEM value to rd
                ALUOp_r         <= 4'b0000;                     // ADDI (rv1 + imm)
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b010;                      // imm
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
                dwe_r           <= 4'b0000;
            end
            
            5'b01000:       // Stores                       
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b010;                      // imm
                ALUOp_r         <= 4'b0000;                     // ADDI (rv1 + imm)
                RegWrite_r      <= 0;                            

                case(reset)
                    1: dwe_r <= 4'b0000;
                    0: // not reset hence work normally
                    begin
                    case(instr[14:12])
                        3'b000: // SB
                        begin
                            case(ALU_out[1:0])
                                2'b00:  dwe_r <= 4'b0001;
                                2'b01:  dwe_r <= 4'b0010;
                                2'b10:  dwe_r <= 4'b0100;
                                2'b11:  dwe_r <= 4'b1000;
                                default: dwe_r <= 4'b0000; //illegal
                            endcase
                        end

                        3'b001: // SH
                        begin
                            case(ALU_out[1:0])
                                2'b00: dwe_r <= 4'b0011;
                                2'b10: dwe_r <= 4'b1100;
                                default: // illegal
                                        dwe_r <= 4'b0000;
                            endcase
                        end
                        
                        3'b010: // SW
                        begin
                            dwe_r <= ALU_out[1:0] == 2'b00 ? 4'b1111 : 4'b0000;
                        end
                        
                        default: dwe_r <= 4'b0000; //illegal
                    endcase
                    end
                endcase
            end
            
            5'b00100:       // Immediate Arithmetic Ops     
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALUOp_r         <= {instr[30], instr[14:12]} == 4'b1101 ? {instr[30], instr[14:12]} : {1'b0, instr[14:12]};   // Use funct3, op(rv1, imm). Check for SRAI, else first bit 0
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b010;                      // imm
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
            end
            
            5'b01100:       // Register Arithmetic Ops      
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALUOp_r         <= {instr[30], instr[14:12]};   // Use funct3, funct7, op(rv1, rv2)
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b100;                      // rv2
                RegWrite_r      <= reset == 1 ? 0 : (instr[11:7] != 5'b0 ? 1 : 0);
            end  

            default:        // illegal opcode, respond like NOP
            begin
                B_Target_r      <= 3'b100;                      // PC+4
                MemToReg_r      <= 0;
                ALUOp_r         <= 4'b0000;                     // ADDI but don't care
                dwe_r           <= 4'b0000;
                ALU_rv1_r       <= 3'b100;                      // rv1
                ALU_rv2_r       <= 3'b100;                      // rv2
                RegWrite_r      <= 0;
            end     
        endcase
    end

endmodule