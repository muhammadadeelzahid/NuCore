`timescale 1ns / 1ps
// Program counter.
//
// Counts up by one on every clock. `restart` pulls it back to zero
// synchronously; `rst_n` clears it asynchronously.
module program_counter #(
    parameter WIDTH = 6
) (
    input                  clk,
    input                  rst_n,
    input                  restart,
    output reg [WIDTH-1:0] pc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= {WIDTH{1'b0}};
        else if (restart)
            pc <= {WIDTH{1'b0}};
        else
            pc <= pc + 1'b1;
    end

endmodule
