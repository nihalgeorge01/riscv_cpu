//                              -*- Mode: Verilog -*-
// Filename        : mask_n_shift.v
// Description     : Masking and Shifting for Load Ops
// Author          : Nihal John George
// 

module mask_n_shift(
    input [1:0] twolsb,
    input [2:0] funct3,
    input [31:0] drdata,

    output [31:0] sliced_drdata
);

    reg [31:0] sliced_drdata;

    always @(*)
    begin
        case(funct3)
            3'b000: // LB
            begin
                case(twolsb)
                    2'b00: sliced_drdata <= $signed({drdata[7:0]});
                    2'b01: sliced_drdata <= $signed({drdata[15:8]});
                    2'b10: sliced_drdata <= $signed({drdata[23:16]});
                    2'b11: sliced_drdata <= $signed({drdata[31:24]});
                    default: sliced_drdata <= 32'b0;    
                endcase
            end

            3'b001: // LH
            begin
                case(twolsb)
                    2'b00: sliced_drdata <= $signed({drdata[15:0]});
                    2'b10: sliced_drdata <= $signed({drdata[31:16]});
                    default: sliced_drdata <= 32'b0;
                endcase    
            end

            3'b010: // LW
            begin
                case(twolsb)
                    2'b00: sliced_drdata <= drdata;
                    default: sliced_drdata <= 32'b0;
                endcase
            end

            3'b100: // LBU
            begin
                case(twolsb)
                    2'b00: sliced_drdata <= {24'b0, drdata[7:0]};
                    2'b01: sliced_drdata <= {24'b0, drdata[15:8]};
                    2'b10: sliced_drdata <= {24'b0, drdata[23:16]};
                    2'b11: sliced_drdata <= {24'b0, drdata[31:24]};
                    default: sliced_drdata <= 32'b0;    
                endcase
            end

            3'b101: // LHU
            begin
                case(twolsb)
                    2'b00: sliced_drdata <= {16'b0, drdata[15:0]};
                    2'b10: sliced_drdata <= {16'b0, drdata[31:16]};
                    default: sliced_drdata <= 32'b0;
                endcase    
            end

            default: //illegal
                sliced_drdata <= 32'b0;
        endcase
    end

endmodule