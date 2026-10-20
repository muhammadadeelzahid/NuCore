`timescale 1ns / 1ps
// Instruction decoder (pipeline stage 1).
//
// Registers the fields of the fetched instruction together with the
// one-hot control strobes derived from its opcode. Everything the execute
// stage needs is therefore aligned to the same clock edge.
module instruction_decoder (
    input             clk,
    input             rst_n,
    input      [38:0] instr,

    output reg [2:0]  opcode,
    output reg [3:0]  addr_a,
    output reg [3:0]  addr_b,
    output reg [31:0] imm,
    output reg        write_a,     // store immediate into register file A
    output reg        write_b,     // store immediate into register file B
    output reg        alu_en,      // perform an ALU operation and latch its result
    output reg        soft_reset   // RESET instruction: clear all state
);

    `include "nucore_opcodes.vh"

    wire [OPCODE_WIDTH-1:0] fetched_opcode = instr[38:36];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode     <= OP_RESET;
            addr_a     <= 4'd0;
            addr_b     <= 4'd0;
            imm        <= 32'd0;
            write_a    <= 1'b0;
            write_b    <= 1'b0;
            alu_en     <= 1'b0;
            soft_reset <= 1'b0;    // the asynchronous reset already cleared everything
        end else begin
            opcode     <= fetched_opcode;
            addr_a     <= instr[35:32];
            addr_b     <= instr[31:28];
            imm        <= instr[31:0];
            write_a    <= (fetched_opcode == OP_STORE_A);
            write_b    <= (fetched_opcode == OP_STORE_B);
            alu_en     <= (fetched_opcode >= OP_ADD);
            soft_reset <= (fetched_opcode == OP_RESET);
        end
    end

endmodule
