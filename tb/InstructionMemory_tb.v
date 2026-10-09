`timescale 1ns/1ps

module InstructionMemory_tb;

    reg [31:0] address;
    reg reset;
    wire [31:0] instruction;

    // Instantiate Instruction Memory
    InstructionMemory dut (
        .address(address),
        .reset(reset),
        .instruction(instruction)
    );

    initial begin
        reset = 1'b0;
        #1;
        reset = 1'b1;
        #1;
        reset = 1'b0;

        // Test addresses
        address = 32'h00000000;
        #10;

        address = 32'h00000004;
        #10;

        address = 32'h00000008;
        #10;

        address = 32'h0000000C;
        #10;

        $display("Instruction Memory test completed.");

        $finish;
    end

endmodule