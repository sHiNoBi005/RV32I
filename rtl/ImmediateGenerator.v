module ImmediateGenerator(
    input [31:0] instruction,
    output reg [31:0] immediate
);

// Generate the sign-extended or shifted immediate based on the opcode.
// Supported formats: I, S, B, U and J.
// This module is combinational: it does not use a clock.

always @(*) begin
    immediate = 32'b0; // Safe default for unsupported opcodes.

    case (instruction[6:0])

        // I-type: loads, ALU-immediate instructions and JALR.
        7'b0000011, // LOAD
        7'b0010011, // OP-IMM
        7'b1100111: // JALR
            immediate = {{20{instruction[31]}}, instruction[31:20]};

        // S-type: STORE
        7'b0100011:
            immediate = {{20{instruction[31]}},
                         instruction[31:25],
                         instruction[11:7]};

        // B-type: conditional branches.
        // Immediate bit 0 is always zero because branch targets are aligned.
        7'b1100011:
            immediate = {{19{instruction[31]}},
                         instruction[31],
                         instruction[7],
                         instruction[30:25],
                         instruction[11:8],
                         1'b0};

        // U-type: LUI and AUIPC.
        7'b0110111, // LUI
        7'b0010111: // AUIPC
            immediate = {instruction[31:12], 12'b0};

        // J-type: JAL.
        // Immediate bit 0 is always zero because jump targets are aligned.
        7'b1101111:
            immediate = {{11{instruction[31]}},
                         instruction[31],
                         instruction[19:12],
                         instruction[20],
                         instruction[30:21],
                         1'b0};

        default:
            immediate = 32'b0;
    endcase
end

endmodule
