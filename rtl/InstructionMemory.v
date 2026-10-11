module InstructionMemory(
    input [31:0] address,
    output [31:0] instruction
);

    reg [31:0] memory [0:255];

    // Load the program at simulation startup
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'b0;

        $readmemh("programs/instructions.mem", memory);
    end

    // Fetch the instruction at the given byte address
    assign instruction = memory[address[9:2]];

endmodule
