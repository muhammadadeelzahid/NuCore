// NuCore instruction encoding.
//
// Every instruction is 39 bits wide:
//
//   [38:36] opcode
//   [35:32] register address A  (store destination, or ALU operand A)
//   [31:28] register address B  (ALU operand B)
//   [31:0]  immediate value     (store instructions only)
//
// Include this file *inside* a module body so the localparams are scoped
// to that module and do not leak as global macros. Not every module uses
// every constant, so the unused-parameter lint is disabled for this file.

// verilator lint_off UNUSEDPARAM
localparam INSTR_WIDTH = 39;
localparam OPCODE_WIDTH = 3;
localparam REG_ADDR_WIDTH = 4;
localparam DATA_WIDTH = 32;

localparam [OPCODE_WIDTH-1:0] OP_RESET   = 3'b000;  // clear register files and output registers, restart program
localparam [OPCODE_WIDTH-1:0] OP_STORE_A = 3'b001;  // REG_FILE_A[addr_a] <= imm
localparam [OPCODE_WIDTH-1:0] OP_STORE_B = 3'b010;  // REG_FILE_B[addr_a] <= imm
localparam [OPCODE_WIDTH-1:0] OP_ADD     = 3'b011;  // result <= A[addr_a] +  B[addr_b]
localparam [OPCODE_WIDTH-1:0] OP_SUB     = 3'b100;  // result <= A[addr_a] -  B[addr_b]
localparam [OPCODE_WIDTH-1:0] OP_OR      = 3'b101;  // result <= A[addr_a] |  B[addr_b]
localparam [OPCODE_WIDTH-1:0] OP_AND     = 3'b110;  // result <= A[addr_a] &  B[addr_b]
localparam [OPCODE_WIDTH-1:0] OP_SHL     = 3'b111;  // result <= A[addr_a] << B[addr_b]
// verilator lint_on UNUSEDPARAM
