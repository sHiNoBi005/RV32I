`timescale 1ns/1ps

module Top_tb;

    reg clk = 0;
    reg reset = 1;

    wire [31:0] PC_out;
    wire [31:0] instruction;
    wire [31:0] ALU_result;
    wire ALU_zero;
    wire [31:0] memory_read_data;
    wire [31:0] writeback_data;

    Top dut (
        .clk(clk),
        .reset(reset),
        .PC_out(PC_out),
        .instruction(instruction),
        .ALU_result(ALU_result),
        .ALU_zero(ALU_zero),
        .memory_read_data(memory_read_data),
        .writeback_data(writeback_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/top_tb.vcd");
        $dumpvars(0, Top_tb);

        // Reset the processor.
        repeat (2) @(posedge clk);
        #1;

        if (PC_out !== 32'd0)
            $fatal(1, "Reset failed: PC = %h", PC_out);

        // The first instruction is: add x3, x1, x2.
        if (instruction !== 32'h002081B3)
            $fatal(1, "Instruction fetch failed: %h", instruction);

        // Seed the source registers and execute the ADD instruction.
        dut.register_file.registers[1] = 32'd20;
        dut.register_file.registers[2] = 32'd3;
        reset = 0;

        @(posedge clk);
        #1;

        if (dut.register_file.registers[3] !== 32'd23)
            $fatal(1, "ADD failed: x3 = %h",
                   dut.register_file.registers[3]);

        $display("PASS: Top smoke test completed.");
        $finish;
    end

endmodule
