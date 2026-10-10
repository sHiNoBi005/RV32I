module ControlUnit(
    OPcode,
    branch,
    MemRead,
    MemtoReg,
    MemWrite,
    ALUScr,
    RegWrite,
    ALUOp_out
);

input [6:0] OPcode;
output reg branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite;
output reg [1:0] ALUOp_out;

// Decode the instruction class from opcode first.
// All outputs receive safe defaults so unsupported opcodes
// never infer latches.
always @(*) begin
    branch    = 1'b0;
    MemRead   = 1'b0;
    MemtoReg  = 1'b0;
    MemWrite  = 1'b0;
    ALUScr    = 1'b0;
    RegWrite  = 1'b0;
    ALUOp_out = 2'b11;  // unsupported/default operation

    case (OPcode)
        7'b0110011: begin // R-type register-register: add/sub/and/or etc.
            RegWrite  = 1'b1;
            ALUScr    = 1'b0;
            ALUOp_out = 2'b10; // ALUControl must inspect funct3/funct7
        end

        7'b0010011: begin // I-type ALU-immediate instructions (e.g. ADDI)
            RegWrite  = 1'b1;
            ALUScr    = 1'b1;
            ALUOp_out = 2'b10; // supported operations decode by funct3/funct7
        end

        7'b0000011: begin // Loads
            RegWrite  = 1'b1;
            MemRead   = 1'b1;
            MemtoReg  = 1'b1;
            ALUScr    = 1'b1;
            ALUOp_out = 2'b00; // calculate address with ADD
        end

        7'b0100011: begin // Stores
            MemWrite  = 1'b1;
            ALUScr    = 1'b1;
            ALUOp_out = 2'b00; // calculate address with ADD
        end

        7'b1100011: begin // Conditional branches
            branch    = 1'b1;
            ALUOp_out = 2'b01; // legacy/simple branch comparison uses SUB
        end

        default: begin
            // Safe control values for unsupported opcodes.
        end
    endcase
end

endmodule
