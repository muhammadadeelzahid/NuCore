`timescale 1ns / 1ps
// Self-checking testbench for NuCore.
//
// The testbench loads the same program file as the DUT and runs it through
// a cycle-free reference model of the instruction set. After every
// instruction the DUT's registered outputs (result, zero flag, Data_A,
// Data_B and the six seven-segment displays) are compared with the model.
//
// Scenarios:
//   1. Reset, run the whole program twice (covers the automatic restart on
//      the RESET instruction).
//   2. Assert reset part-way through the program, check that the outputs
//      clear immediately, release and run the program again.
//
// Run with ModelSim-Altera from Quartus (Tools > Run Simulation Tool >
// RTL Simulation, NativeLink).
//
// Override the program with +define+PROGRAM_FILE="path" at compile time.
// ModelSim defines MODEL_TECH; NativeLink runs it in
// <project>/simulation/modelsim, so the ModelSim default points two
// directories up to find memory.dat. The plain default serves any other
// simulator started from the project root.

`ifndef PROGRAM_FILE
  `ifdef MODEL_TECH
    `define PROGRAM_FILE "../../memory.dat"
  `else
    `define PROGRAM_FILE "memory.dat"
  `endif
`endif

module NuCore_TB;

    `include "../rtl/nucore_opcodes.vh"

    localparam CLK_PERIOD       = 10;   // ns, as in the design report
    localparam PC_WIDTH         = 6;
    localparam PROGRAM_DEPTH    = 1 << PC_WIDTH;
    localparam PIPELINE_LATENCY = 2;    // clocks from fetch to visible result

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    reg  [1:0]  KEY;
    wire [31:0] Data_A, Data_B, result;
    wire [0:6]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [0:0]  LEDR;

    NuCore #(
        .PROGRAM_FILE(`PROGRAM_FILE)
    ) dut (
        .KEY   (KEY),
        .HEX0  (HEX0),
        .HEX1  (HEX1),
        .HEX2  (HEX2),
        .HEX3  (HEX3),
        .HEX4  (HEX4),
        .HEX5  (HEX5),
        .LEDR  (LEDR),
        .result(result),
        .Data_A(Data_A),
        .Data_B(Data_B)
    );

    wire clk = KEY[0];

    initial KEY[0] = 1'b0;
    always #(CLK_PERIOD / 2) KEY[0] = ~KEY[0];

    // ------------------------------------------------------------------
    // Reference model
    // ------------------------------------------------------------------
    reg [INSTR_WIDTH-1:0] program_mem [0:PROGRAM_DEPTH-1];
    integer               program_length;

    reg [DATA_WIDTH-1:0]  ref_file_a [0:15];
    reg [DATA_WIDTH-1:0]  ref_file_b [0:15];
    reg [PC_WIDTH-1:0]    ref_pc;
    reg [DATA_WIDTH-1:0]  exp_result, exp_data_a, exp_data_b;
    reg                   exp_zero;
    reg [OPCODE_WIDTH-1:0] last_opcode;

    integer errors = 0;
    integer checks = 0;
    integer k;
    integer fd;

    task ref_reset;
        begin
            for (k = 0; k < 16; k = k + 1) begin
                ref_file_a[k] = 0;
                ref_file_b[k] = 0;
            end
            ref_pc     = 0;
            exp_result = 0;
            exp_zero   = 1'b1;
            exp_data_a = 0;
            exp_data_b = 0;
        end
    endtask

    // Execute one instruction in the reference model.
    task ref_step;
        reg [INSTR_WIDTH-1:0] instr;
        reg [OPCODE_WIDTH-1:0] op;
        reg [3:0] addr_a, addr_b;
        reg [DATA_WIDTH-1:0] a, b;
        begin
            instr  = program_mem[ref_pc];
            op     = instr[38:36];
            addr_a = instr[35:32];
            addr_b = instr[31:28];
            last_opcode = op;

            case (op)
                OP_RESET: begin
                    ref_reset;
                end
                OP_STORE_A: ref_file_a[addr_a] = instr[31:0];
                OP_STORE_B: ref_file_b[addr_a] = instr[31:0];
                default: begin
                    a = ref_file_a[addr_a];
                    b = ref_file_b[addr_b];
                    case (op)
                        OP_ADD:  exp_result = a + b;
                        OP_SUB:  exp_result = a - b;
                        OP_OR:   exp_result = a | b;
                        OP_AND:  exp_result = a & b;
                        OP_SHL:  exp_result = a << b;
                        default: exp_result = 0;
                    endcase
                    exp_zero   = (exp_result == 0);
                    exp_data_a = a;
                    exp_data_b = b;
                end
            endcase

            if (op != OP_RESET)
                ref_pc = ref_pc + 1;
        end
    endtask

    function [0:6] seg7;
        input [3:0] bin;
        case (bin)
            4'h0: seg7 = 7'b0000001;  4'h1: seg7 = 7'b1001111;
            4'h2: seg7 = 7'b0010010;  4'h3: seg7 = 7'b0000110;
            4'h4: seg7 = 7'b1001100;  4'h5: seg7 = 7'b0100100;
            4'h6: seg7 = 7'b0100000;  4'h7: seg7 = 7'b0001111;
            4'h8: seg7 = 7'b0000000;  4'h9: seg7 = 7'b0001100;
            4'hA: seg7 = 7'b0001000;  4'hB: seg7 = 7'b1100000;
            4'hC: seg7 = 7'b0110001;  4'hD: seg7 = 7'b1000010;
            4'hE: seg7 = 7'b0110000;  default: seg7 = 7'b0111000;
        endcase
    endfunction

    task check_outputs;
        input [8*32-1:0] label;
        reg ok;
        begin
            checks = checks + 1;
            ok = (result === exp_result) && (LEDR[0] === exp_zero) &&
                 (Data_A === exp_data_a) && (Data_B === exp_data_b) &&
                 (HEX0 === seg7(exp_data_a[3:0])) && (HEX1 === seg7(exp_data_a[7:4])) &&
                 (HEX2 === seg7(exp_data_b[3:0])) && (HEX3 === seg7(exp_data_b[7:4])) &&
                 (HEX4 === seg7(exp_result[3:0])) && (HEX5 === seg7(exp_result[7:4]));
            if (!ok) begin
                errors = errors + 1;
                $display("FAIL [%0s] t=%0t op=%b: result=%0d (exp %0d) zero=%b (exp %b) A=%0d (exp %0d) B=%0d (exp %0d)",
                         label, $time, last_opcode, result, exp_result, LEDR[0], exp_zero,
                         Data_A, exp_data_a, Data_B, exp_data_b);
            end
        end
    endtask

    // End the simulation. Under ModelSim $finish pops up a "finish?" dialog
    // in GUI mode; $stop leaves the waveform open instead, and in batch
    // mode returns control to the do script so it can quit.
    task end_sim;
        begin
`ifdef MODEL_TECH
            $stop;
`else
            $finish;
`endif
        end
    endtask

    // Hold reset low for a few clocks and release it mid-cycle.
    task apply_reset;
        begin
            @(negedge clk);
            KEY[1] = 1'b0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            KEY[1] = 1'b1;
            ref_reset;
            last_opcode = OP_RESET;
        end
    endtask

    // Run `count` instructions from the current reference-model state,
    // checking the DUT after every one. Must be called immediately after
    // apply_reset so that the pipeline fill is accounted for.
    task run_instructions;
        input integer count;
        integer n;
        begin
            repeat (PIPELINE_LATENCY) @(posedge clk);
            for (n = 0; n < count; n = n + 1) begin
                @(negedge clk);
                ref_step;
                check_outputs("program");
                if (last_opcode >= OP_ADD)
                    $display("  pc=%0d op=%b A=%0d B=%0d -> result=%0d zero=%b",
                             ref_pc - 1, last_opcode, Data_A, Data_B, result, LEDR[0]);
                @(posedge clk);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Test sequence
    // ------------------------------------------------------------------
    initial begin
        // Fail loudly if the program file is not where we expect it,
        // otherwise $readmemb only warns and the DUT runs an empty ROM.
        fd = $fopen(`PROGRAM_FILE, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open program file \"%0s\".", `PROGRAM_FILE);
            $display("       Run ModelSim from <project>/simulation/modelsim (Quartus NativeLink)");
            $display("       or compile with +define+PROGRAM_FILE=\"<path>\".");
            $display("TEST FAILED");
            end_sim;
        end
        $fclose(fd);

        for (k = 0; k < PROGRAM_DEPTH; k = k + 1)
            program_mem[k] = {INSTR_WIDTH{1'b0}};
        $readmemb(`PROGRAM_FILE, program_mem);

        // Program length = index of the first RESET instruction + 1
        // (or the whole memory if there is none).
        program_length = PROGRAM_DEPTH;
        for (k = PROGRAM_DEPTH - 1; k >= 0; k = k - 1)
            if (program_mem[k][38:36] == OP_RESET)
                program_length = k + 1;

        $display("NuCore testbench: program %0s, %0d instructions", `PROGRAM_FILE, program_length);

        KEY[1] = 1'b1;

        // Scenario 1: run the program twice through, crossing the restart.
        $display("--- Scenario 1: full program, twice");
        apply_reset;
        run_instructions(2 * program_length + 3);

        // Scenario 2: asynchronous reset in the middle of the program.
        $display("--- Scenario 2: reset mid-program");
        apply_reset;
        run_instructions(program_length / 2 + 1);

        @(negedge clk);
        KEY[1] = 1'b0;
        #1;
        ref_reset;
        last_opcode = OP_RESET;
        check_outputs("async reset");
        @(posedge clk);
        @(negedge clk);
        KEY[1] = 1'b1;
        run_instructions(program_length);

        $display("--- %0d checks, %0d errors", checks, errors);
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
        end_sim;
    end

    // Watchdog
    initial begin
        #(CLK_PERIOD * 2000);
        $display("TEST FAILED: watchdog timeout");
        end_sim;
    end

endmodule
