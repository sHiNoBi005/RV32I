`timescale 1ns/1ps

module InstructionMemory_tb;

    reg [31:0] address;
    wire [31:0] instruction;

    // Instantiate Instruction Memory
    InstructionMemory dut (
        .address(address),
        .instruction(instruction)
    );

    initial begin
        $dumpfile("InstructionMemory.vcd");
        $dumpvars(0, InstructionMemory_tb);

        address = 32'h00000000;

        $monitor("Time=%0t | Address=%h | Instruction=%h",
                 $time, address, instruction);

        #10 address = 32'h00000004;
        #10 address = 32'h00000008;
        #10 address = 32'h0000000C;
        #10;

        $display("Instruction Memory test completed.");
        $finish;
    end

endmodule