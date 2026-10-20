`timescale 1ns / 1ps
// Register file with one synchronous write port and one asynchronous
// read port. `clear` zeroes every entry in a single clock.
module register_file #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
) (
    input                   clk,
    input                   rst_n,
    input                   clear,
    input                   we,
    input  [ADDR_WIDTH-1:0] waddr,
    input  [DATA_WIDTH-1:0] wdata,
    input  [ADDR_WIDTH-1:0] raddr,
    output [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] regs [0:DEPTH-1];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (clear) begin
            for (i = 0; i < DEPTH; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (we) begin
            regs[waddr] <= wdata;
        end
    end

    assign rdata = regs[raddr];

endmodule
