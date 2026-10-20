`timescale 1ns / 1ps
// NuCore board top level for the Terasic DE1-SoC.
//
//   KEY[0]  clock  (one instruction per button press)
//   KEY[1]  reset  (active low: hold the button to reset)
//   HEX1:0  low byte of operand A         (Data_A)
//   HEX3:2  low byte of operand B         (Data_B)
//   HEX5:4  low byte of the ALU result    (result)
//   LEDR[0] zero flag
//
// The 32-bit result, Data_A and Data_B ports exist for simulation and are
// declared as virtual pins in the Quartus project.
module NuCore #(
    parameter PROGRAM_FILE = "memory.dat"
) (
    input  [1:0]  KEY,
    output [0:6]  HEX0,
    output [0:6]  HEX1,
    output [0:6]  HEX2,
    output [0:6]  HEX3,
    output [0:6]  HEX4,
    output [0:6]  HEX5,
    output [0:0]  LEDR,
    output [31:0] result,
    output [31:0] Data_A,
    output [31:0] Data_B
);

    wire clk   = KEY[0];
    wire rst_n = KEY[1];
    wire zero;

    nucore_core #(
        .PROGRAM_FILE(PROGRAM_FILE)
    ) u_core (
        .clk   (clk),
        .rst_n (rst_n),
        .result(result),
        .zero  (zero),
        .data_a(Data_A),
        .data_b(Data_B)
    );

    assign LEDR[0] = zero;

    seg_7 u_hex0 (.bin(Data_A[3:0]), .seg(HEX0));
    seg_7 u_hex1 (.bin(Data_A[7:4]), .seg(HEX1));
    seg_7 u_hex2 (.bin(Data_B[3:0]), .seg(HEX2));
    seg_7 u_hex3 (.bin(Data_B[7:4]), .seg(HEX3));
    seg_7 u_hex4 (.bin(result[3:0]), .seg(HEX4));
    seg_7 u_hex5 (.bin(result[7:4]), .seg(HEX5));

endmodule
