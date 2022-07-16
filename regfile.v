//                              -*- Mode: Verilog -*-
// Filename        : regfile.v
// Description     : Register File
// Author          : Nihal John George
// 

module regfile(
    input RegWrite,
    input clk,
    input reset,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] rwdata,
    
    output [31:0] rv1,
    output [31:0] rv2
);
    
    reg [31:0] bank [0:31]; // register bank
    wire [31:0] rv1, rv2;
    integer i;
    
    // Initialize regs to 0
    initial 
    begin
        for (i=0 ; i<32 ; i=i+1)
            bank[i] <= 0;
    end
    
    // Clocked Write
    always @(posedge clk)
    begin
        if (reset == 1)
        begin
            for (i=0 ; i<32 ; i=i+1)
                bank[i] <= 0;
        end
        else
        begin
            if (RegWrite && rd != 5'b0)    // write to x0 illegal in RISC-V
                bank[rd] <= rwdata;
            else
                bank[0] <= 0;
        end   
    end
    
    // Async read
    assign rv1 = bank[rs1];
    assign rv2 = bank[rs2];
endmodule