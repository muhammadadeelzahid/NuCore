`timescale 1ns / 1ps
// Instruction memory (read-only).
//
// The program is loaded from PROGRAM_FILE with $readmemb, one 39-bit
// binary instruction per line. Entries not covered by the file read as
// all zeros, which is the RESET opcode, so a program that runs off the end
// of the file simply restarts.
module instruction_memory #(
    parameter ADDR_WIDTH   = 6,
    parameter PROGRAM_FILE = "memory.dat"
) (
    input  [ADDR_WIDTH-1:0] addr,
    output [38:0]           instr
);

    `include "nucore_opcodes.vh"

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [INSTR_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        // synthesis translate_off
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {INSTR_WIDTH{1'b0}};
        // synthesis translate_on
        $readmemb(PROGRAM_FILE, mem);
    end

    assign instr = mem[addr];

endmodule
