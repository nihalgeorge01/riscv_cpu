//                              -*- Mode: Verilog -*-
// Filename        : cpu.v
// Description     : CPU (containing control, ALU, regfile, ImmGen and counter logic)
// Author          : Nihal John George
// 
/*
alu.v
regfile.v
immgen.v
mask_n_shift.v
control.v
cpu.v
cpu_tb.v
dmem.v
imem.v
*/

module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);

    // --------------- DECLARATIONS
    //
    //

    // Four below previously reg
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;
    reg [31:0] iaddr_r;

    wire [3:0] dwe_w;
    wire [31:0] daddr_w;
    wire [31:0] dwdata_w;
    wire [31:0] PC_new;
    
    // ALU
    wire [31:0] ALU_a, ALU_b, ALU_out;
    
    // Regfile in
    wire [4:0] rs1, rs2, rd;
    wire [31:0] rwdata;
    wire [31:0] rv1, rv2;
    
    // Immgen out (Immgen in is idata)
    wire [31:0] imm;

    // Control Out
    wire [2:0] B_Target, ALU_rv1, ALU_rv2;
    wire MemToReg, RegWrite;
    wire [3:0] ALUOp;

    // Store Utilities - make copies of lower byte/2 bytes and form a word. Useful for SB, SH
    wire [31:0] twocopy, fourcopy;
    
    // Load Utils
    wire [31:0] sliced_drdata;

    // rv1+imm separate wire for JALR
    wire [31:0] rv1_plus_imm_full;
    wire [31:0] rv1_plus_imm_except_last;

    // --------------- ASSIGNMENTS
    //
    // 
    assign rs1 = idata[19:15];
    assign rs2 = idata[24:20];
    assign rd  = idata[11:7];

    // DMEM write
    assign daddr_w = {ALU_out[31:2], 2'b00};      // Word aligned daddr. Selective write using dwe, selective read using combi logic after read
    // Regfile write
    assign rwdata = MemToReg == 1 ? sliced_drdata : ALU_out;

    // ALU Input logic
    assign ALU_a = ALU_rv1 == 3'b100 ? rv1 : (ALU_rv1 == 3'b010 ? 32'b0 : (ALU_rv1 == 3'b001 ? iaddr : 32'b0));
    assign ALU_b = ALU_rv2 == 3'b100 ? rv2 : (ALU_rv2 == 3'b010 ? imm : (ALU_rv2 == 3'b001 ? {29'b0, 3'b100} : 32'b0));
    
    // Branch Target logic
    assign rv1_plus_imm_full = rv1 + imm;
    assign rv1_plus_imm_except_last = rv1_plus_imm_full[31:1];
    assign PC_new = B_Target == 3'b100 ? iaddr_r+4 : (B_Target == 3'b010 ? iaddr_r+imm : (B_Target == 3'b001 ? {rv1_plus_imm_except_last, 1'b0} : iaddr_r+4));
    
    // Store Utils assign
    assign twocopy = {rv2[15:0], rv2[15:0]};        // For SH
    assign fourcopy = {rv2[7:0], rv2[7:0], rv2[7:0], rv2[7:0]}; // For SB
    assign dwdata_w = idata[14:12] == 3'b000 ? fourcopy : (idata[14:12] == 3'b001 ? twocopy : (idata[14:12] == 3'b010 ? rv2 : 32'b0));

    // always at posedge clock
    // 1. Update PC from PC_new, get new instr
    // 2. Read the rs1, rs2 from regfile. Sometimes they are garbage, don't worry, muxes after regfile and before ALU will handle
    // 3. Control signals are sent, ALU and branch target logic does required computations. 
    // 4. Value to be written to reg/DMEM/PC will wait till next cycle

    always @(*)
    begin
        case(reset)
            0:
            begin
                daddr   <= daddr_w;
                dwe     <= dwe_w;
                dwdata  <= dwdata_w;
            end
            1:
            begin
                daddr   <= 0;
                dwe     <= 0;
                dwdata  <= 0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
            iaddr_r <= -4;
            //daddr <= 0;
            //dwdata <= 0;
            //dwe <= 0;
        end else begin 
            iaddr = PC_new;
            iaddr_r = iaddr; 
        end
    end
    
    // Instantiate ALU
    alu _alu(
        .a(ALU_a),
        .b(ALU_b),
        .op(ALUOp),

        .out(ALU_out)
    );
    
    // Instantiate RegFile
    regfile _regfile(
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rwdata(rwdata),
        .reset(reset),
        
        .rv1(rv1),
        .rv2(rv2)
    );
    
    // Instantiate ImmGen
    immgen _immgen(
        .instr(idata),
        .imm(imm)
    );
    
    // Instantiate Control Module
    control _control(
        .instr(idata),
        .ALU_out(ALU_out),
        .reset(reset),
        
        .B_Target(B_Target),
        .MemToReg(MemToReg),
        .ALUOp(ALUOp),
        .dwe(dwe_w),
        .ALU_rv1(ALU_rv1),
        .ALU_rv2(ALU_rv2),
        .RegWrite(RegWrite)
    );

    // Instantiate Mask-n-Shift
    mask_n_shift _mask_n_shift(
        .twolsb(ALU_out[1:0]),
        .funct3(idata[14:12]),
        .drdata(drdata),

        .sliced_drdata(sliced_drdata)
    );

endmodule