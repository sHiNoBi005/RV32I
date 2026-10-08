`timescale 1ns/1ps

module ProgramCounter_tb;

    reg clk;
    reg reset;
    reg [31:0] PC_in;
    wire [31:0] PC_out;

    // Instantiate the Program Counter
    ProgramCounter dut (
        .clk(clk),
        .reset(reset),
        .PC_in(PC_in),
        .PC_out(PC_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Create waveform
        $dumpfile("sim/ProgramCounter.vcd");
        $dumpvars(0, ProgramCounter_tb);

        // Initial values
        clk = 0;
        reset = 1;
        PC_in = 32'h00000000;

        // Hold reset for one clock cycle
        #10;

        // Release reset
        reset = 0;

        // Test PC = 4
        PC_in = 32'h00000004;
        #10;

        // Test PC = 8
        PC_in = 32'h00000008;
        #10;

        // Test PC = 12
        PC_in = 32'h0000000C;
        #10;

        // Test PC = 16
        PC_in = 32'h00000010;
        #10;

        $display("Program Counter test completed.");

        $finish;
    end

endmodule