module ControlUnit(
    OPcode,
    func3,
    func7,
    branch,
    jump,
    MemRead,
    MemtoReg,
    MemWrite,
    ALUScr,
    RegWrite,
    ALUControlOut
);

input [6:0] OPcode;
input [2:0] func3;
input [6:0] func7;

output reg branch;
output reg jump;
output reg MemRead;
output reg MemtoReg;
output reg MemWrite;
output reg ALUScr;
output reg RegWrite;
output reg [3:0] ALUControlOut;

always @(*) begin
    // Safe defaults for unsupported instructions.
    branch = 1'b0;
    jump = 1'b0;
    MemRead = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    ALUScr = 1'b0;
    RegWrite = 1'b0;
    ALUControlOut = 4'b1111;

    case (OPcode)

        // R-type instructions
        7'b0110011: begin
            case (func3)

                // ADD/SUB
                3'b000: begin
                    case (func7)
                        7'b0000000: begin
                            ALUControlOut = 4'b0010; // ADD
                            RegWrite = 1'b1;
                        end
                        7'b0100000: begin
                            ALUControlOut = 4'b0110; // SUB
                            RegWrite = 1'b1;
                        end
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                // SLL
                3'b001: begin
                    if(func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0011;
                        RegWrite = 1'b1;
                    end
                end

                // SLT
                3'b010: begin
                    if(func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0100;
                        RegWrite = 1'b1;
                    end
                end

                // SLTU
                3'b011: begin
                    if(func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0101;
                        RegWrite = 1'b1;
                    end
                end

                // XOR
                3'b100: begin
                    if(func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0111;
                        RegWrite = 1'b1;
                    end
                end

                // SRL or SRA
                3'b101: begin
                    case (func7)
                        7'b0000000: begin
                            ALUControlOut = 4'b1000; // SRL
                            RegWrite = 1'b1;
                        end
                        7'b0100000: begin
                            ALUControlOut = 4'b1001; // SRA
                            RegWrite = 1'b1;
                        end
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                // OR
                3'b110: begin
                    if (func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0001;
                        RegWrite = 1'b1;
                    end
                end

                // AND
                3'b111: begin
                    if (func7 == 7'b0000000) begin
                        ALUControlOut = 4'b0000;
                        RegWrite = 1'b1;
                    end
                end
                default: ALUControlOut = 4'b1111;

            endcase
        end

        // I-type ALU instructions
        7'b0010011: begin
            ALUScr = 1'b1;
            case(func3)
                // ADDI
                3'b000: begin
                    ALUControlOut = 4'b0010; // ADDI
                    RegWrite = 1'b1;
                end

                // SLLI
                3'b001: begin
                    ALUControlOut = 4'b0011; // SLLI
                    RegWrite = 1'b1;
                end

                // SLTI
                3'b010: begin
                    ALUControlOut = 4'b0100; // SLTI
                    RegWrite = 1'b1;
                end

                // SLTIU
                3'b011: begin
                    ALUControlOut = 4'b0101; // SLTIU
                    RegWrite = 1'b1;
                end

                // XORI
                3'b100: begin
                    ALUControlOut = 4'b0111; // XORI
                    RegWrite = 1'b1;
                end

                // SRLI or SRAI
                3'b101: begin
                    case (func7)
                        7'b0000000: begin
                            ALUControlOut = 4'b1000; // SRLI
                            RegWrite = 1'b1;
                        end
                        7'b0100000: begin
                            ALUControlOut = 4'b1001; // SRAI
                            RegWrite = 1'b1;
                        end
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                // ORI
                3'b110: begin
                    ALUControlOut = 4'b0001; // ORI
                    RegWrite = 1'b1;
                end

                // ANDI
                3'b111: begin
                    ALUControlOut = 4'b0000; // ANDI
                    RegWrite = 1'b1;
                end
                default: ALUControlOut = 4'b1111;
            endcase
        end

        // Load instructions: LB, LH, LW, LBU and LHU.
        7'b0000011: begin
            case (func3)
                3'b000, // LB
                3'b001, // LH
                3'b010, // LW
                3'b100, // LBU
                3'b101: begin // LHU
                    ALUScr = 1'b1;          // Use the sign-extended I-type immediate.
                    MemRead = 1'b1;         // Read from data memory.
                    MemtoReg = 1'b1;        // Write memory data back to rd.
                    MemWrite = 1'b0;        // A load does not write memory.
                    RegWrite = 1'b1;        // Write the loaded value to rd.
                    ALUControlOut = 4'b0010; // ADD: calculate base + offset.
                end

                default: begin
                    // Invalid load funct3: keep safe defaults.
                end
            endcase
        end

        // Store instructions: SB, SH and SW.
        7'b0100011: begin
            case (func3)
                3'b000, // SB: store byte
                3'b001, // SH: store halfword
                3'b010: begin // SW: store word
                    ALUScr = 1'b1;           // Use the S-type immediate.
                    MemRead = 1'b0;          // A store does not read memory.
                    MemtoReg = 1'b0;         // A store does not write a register.
                    MemWrite = 1'b1;         // Enable data-memory write.
                    RegWrite = 1'b0;         // No destination register write.
                    ALUControlOut = 4'b0010; // ADD: calculate base + offset.
                end

                default: begin
                    // Invalid store funct3: keep safe defaults.
                end
            endcase
        end

        // U-type instructions: LUI and AUIPC.
        // Their instruction class is identified by opcode alone.
        7'b0110111, // LUI
        7'b0010111: begin // AUIPC
            ALUScr = 1'b1;           // Select the U-type immediate for operand B.
            RegWrite = 1'b1;         // Write the result to rd.
            ALUControlOut = 4'b0010; // ADD operation.
        end

        // Conditional branch instructions (B/SB format).
        7'b1100011: begin
            case (func3)
                3'b000: begin // BEQ: compare equal using SUB/zero flag.
                    branch = 1'b1;
                    ALUControlOut = 4'b0110;
                end
                3'b001: begin // BNE: compare not equal using SUB/zero flag.
                    branch = 1'b1;
                    ALUControlOut = 4'b0110;
                end
                3'b100: begin // BLT: signed less-than comparison.
                    branch = 1'b1;
                    ALUControlOut = 4'b0100;
                end
                3'b101: begin // BGE: signed greater/equal; invert SLT result in branch logic.
                    branch = 1'b1;
                    ALUControlOut = 4'b0100;
                end
                3'b110: begin // BLTU: unsigned less-than comparison.
                    branch = 1'b1;
                    ALUControlOut = 4'b0101;
                end
                3'b111: begin // BGEU: unsigned greater/equal; invert SLTU result in branch logic.
                    branch = 1'b1;
                    ALUControlOut = 4'b0101;
                end
                default: begin
                    // Invalid branch funct3: keep safe defaults.
                end
            endcase
        end

        // UJ-format JAL. PC redirection and PC+4 write-back are integrated in Top later.
        7'b1101111: begin
            jump = 1'b1;
            ALUScr = 1'b1;
            RegWrite = 1'b1;
            ALUControlOut = 4'b0010;
        end

        default: begin
            // Unsupported opcode: retain safe defaults.
        end

    endcase
end

endmodule
