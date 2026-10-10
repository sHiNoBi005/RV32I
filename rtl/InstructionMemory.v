module InstructionMemory(
    input [31:0] address,
    output [31:0] instruction
);

    reg [31:0] memory [0:255];

    // Load the program at simulation startup
    initial begin
        $readmemh("instructions.mem", memory);
    end

    // Fetch the instruction at the given byte address
    assign instruction = memory[address[9:2]];

endmodule
