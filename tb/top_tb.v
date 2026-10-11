`timescale 1ps/1ps

module Top_tb;

    reg clk = 0;
    reg reset = 1;

    wire [31:0] PC_out;
    wire [31:0] instruction;

    reg [31:0] expected [0:4];
    integer i;

    // Instantiate the Top module
    Top dut (
        .clk(clk),
        .reset(reset),
        .PC_out(PC_out),
        .instruction(instruction)
    )

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/top_tb.vcd");
        $dumpvars(0, Top_Fetch_tb);

        // Expected instructions at byte addresses 0, 4, 8, 12 and 16.
        expected[0] = 32'h002081B3;
        expected[1] = 32'h40208233;
        expected[2] = 32'h002092B3;
        expected[3] = 32'h00112333;
        expected[4] = 32'h001133B3;

        // Hold reset for two clock edges.
        repeat (2) @(posedge clk);
        #1;

        if (PC_out !== 32'd0)
            $fatal(1, "Fetch reset failed: PC = %h", PC_out);

        if (instruction !== expected[0])
            $fatal(1, "First instruction fetch failed: %h",
                   instruction);

        reset = 0;

        // Check sequential instruction fetching.
        for (i = 1; i <= 4; i = i + 1) begin
            @(posedge clk);
            #1;

            if (PC_out !== (i * 4))
                $fatal(1, "PC failed at step %0d: got %h",
                       i, PC_out);

            if (instruction !== expected[i])
                $fatal(1, "Instruction fetch failed at PC %h: got %h",
                       PC_out, instruction);

            $display("Fetch passed: PC=%h, instruction=%h",
                     PC_out, instruction);
        end

        $display("PASS: Fetch stage works correctly.");
        $finish;
    end