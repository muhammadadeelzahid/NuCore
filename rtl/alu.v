`timescale 1ns / 1ps
// Arithmetic logic unit. Purely combinational; the execute stage registers
// its outputs.
module alu (
    input      [31:0] a,
    input      [31:0] b,
    input      [2:0]  op,
    output reg [31:0] y,
    output            zero
);

    `include "nucore_opcodes.vh"

    always @(*) begin
        case (op)
            OP_ADD:  y = a + b;
            OP_SUB:  y = a - b;
            OP_OR:   y = a | b;
            OP_AND:  y = a & b;
            OP_SHL:  y = a << b;
            default: y = {DATA_WIDTH{1'b0}};
        endcase
    end

    assign zero = (y == {DATA_WIDTH{1'b0}});

endmodule
