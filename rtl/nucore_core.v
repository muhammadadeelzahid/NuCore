`timescale 1ns / 1ps
// NuCore processor core.
//
// Two-stage pipeline:
//
//   fetch   : pc -> instruction_memory -> instr               (combinational)
//   decode  : instr fields and control strobes are registered (instruction_decoder)
//   execute : register-file write / ALU, outputs registered   (this module)
//
// An instruction fetched on clock edge N is decoded into the pipeline
// register on edge N+1 and its effects (register-file write, result,
// zero flag) are visible after edge N+2.
//
// The RESET opcode is handled at both ends of the pipeline: the fetch
// stage restarts the program counter as soon as it sees the opcode, and
// the execute stage clears the register files and output registers one
// clock later. A program therefore loops forever once it reaches a RESET
// instruction (or runs past the end of the loaded program, since empty
// instruction memory reads as RESET).
module nucore_core #(
    parameter PC_WIDTH     = 6,
    parameter PROGRAM_FILE = "memory.dat"
) (
    input             clk,
    input             rst_n,
    output reg [31:0] result,     // registered ALU output
    output reg        zero,       // registered zero flag, result == 0
    output reg [31:0] data_a,     // operand A of the most recent ALU instruction
    output reg [31:0] data_b      // operand B of the most recent ALU instruction
);

    `include "nucore_opcodes.vh"

    // ------------------------------------------------------------------
    // Fetch
    // ------------------------------------------------------------------
    wire [PC_WIDTH-1:0]    pc;
    wire [INSTR_WIDTH-1:0] instr;
    wire                   restart = (instr[38:36] == OP_RESET);

    program_counter #(
        .WIDTH(PC_WIDTH)
    ) u_pc (
        .clk    (clk),
        .rst_n  (rst_n),
        .restart(restart),
        .pc     (pc)
    );

    instruction_memory #(
        .ADDR_WIDTH  (PC_WIDTH),
        .PROGRAM_FILE(PROGRAM_FILE)
    ) u_imem (
        .addr (pc),
        .instr(instr)
    );

    // ------------------------------------------------------------------
    // Decode
    // ------------------------------------------------------------------
    wire [OPCODE_WIDTH-1:0]   d_opcode;
    wire [REG_ADDR_WIDTH-1:0] d_addr_a;
    wire [REG_ADDR_WIDTH-1:0] d_addr_b;
    wire [DATA_WIDTH-1:0]     d_imm;
    wire                      d_write_a;
    wire                      d_write_b;
    wire                      d_alu_en;
    wire                      d_soft_reset;

    instruction_decoder u_decode (
        .clk       (clk),
        .rst_n     (rst_n),
        .instr     (instr),
        .opcode    (d_opcode),
        .addr_a    (d_addr_a),
        .addr_b    (d_addr_b),
        .imm       (d_imm),
        .write_a   (d_write_a),
        .write_b   (d_write_b),
        .alu_en    (d_alu_en),
        .soft_reset(d_soft_reset)
    );

    // ------------------------------------------------------------------
    // Execute
    // ------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] operand_a;
    wire [DATA_WIDTH-1:0] operand_b;
    wire [DATA_WIDTH-1:0] alu_y;
    wire                  alu_zero;

    // Both store opcodes carry their destination in the addr_a field.
    register_file #(
        .ADDR_WIDTH(REG_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_reg_file_a (
        .clk  (clk),
        .rst_n(rst_n),
        .clear(d_soft_reset),
        .we   (d_write_a),
        .waddr(d_addr_a),
        .wdata(d_imm),
        .raddr(d_addr_a),
        .rdata(operand_a)
    );

    register_file #(
        .ADDR_WIDTH(REG_ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_reg_file_b (
        .clk  (clk),
        .rst_n(rst_n),
        .clear(d_soft_reset),
        .we   (d_write_b),
        .waddr(d_addr_a),
        .wdata(d_imm),
        .raddr(d_addr_b),
        .rdata(operand_b)
    );

    alu u_alu (
        .a   (operand_a),
        .b   (operand_b),
        .op  (d_opcode),
        .y   (alu_y),
        .zero(alu_zero)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= {DATA_WIDTH{1'b0}};
            zero   <= 1'b1;
            data_a <= {DATA_WIDTH{1'b0}};
            data_b <= {DATA_WIDTH{1'b0}};
        end else if (d_soft_reset) begin
            result <= {DATA_WIDTH{1'b0}};
            zero   <= 1'b1;
            data_a <= {DATA_WIDTH{1'b0}};
            data_b <= {DATA_WIDTH{1'b0}};
        end else if (d_alu_en) begin
            result <= alu_y;
            zero   <= alu_zero;
            data_a <= operand_a;
            data_b <= operand_b;
        end
    end

endmodule
