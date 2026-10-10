module ALUControl(
    OPcode,
    func3,
    func7,
    ALUControlOut
);

input [6:0] OPcode;
input [2:0] func3;
input [6:0] func7;
output reg [3:0] ALUControlOut;

// Decode hierarchically: opcode -> funct3 -> funct7 where required.
// ALU control encodings match ALU.v:
// 0000 = AND, 0001 = OR, 0010 = ADD, 0110 = SUB.
always @(*) begin
    ALUControlOut = 4'b1111; // Unsupported instruction/encoding by default.

    case (OPcode)
        7'b0110011: begin // R-type: register-register ALU operations
            case (func3)
                3'b000: begin // ADD or SUB; funct7 distinguishes them.
                    case (func7)
                        7'b0000000: ALUControlOut = 4'b0010; // ADD
                        7'b0100000: ALUControlOut = 4'b0110; // SUB
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                3'b111: begin // AND
                    case (func7)
                        7'b0000000: ALUControlOut = 4'b0000;
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                3'b110: begin // OR
                    case (func7)
                        7'b0000000: ALUControlOut = 4'b0001;
                        default:    ALUControlOut = 4'b1111;
                    endcase
                end

                default: ALUControlOut = 4'b1111;
            endcase
        end

        7'b0010011: begin // I-type ALU-immediate operations
            case (func3)
                3'b000: ALUControlOut = 4'b0010; // ADDI
                3'b111: ALUControlOut = 4'b0000; // ANDI
                3'b110: ALUControlOut = 4'b0001; // ORI
                default: ALUControlOut = 4'b1111;
            endcase
        end

        7'b0000011: begin // Loads: address = base + immediate
            ALUControlOut = 4'b0010; // ADD
        end

        7'b0100011: begin // Stores: address = base + immediate
            ALUControlOut = 4'b0010; // ADD
        end

        7'b1100011: begin // Conditional branch comparison
            case (func3)
                3'b000: ALUControlOut = 4'b0110; // BEQ uses subtraction
                3'b001: ALUControlOut = 4'b0110; // BNE uses subtraction
                default: ALUControlOut = 4'b1111; // Other branches not implemented
            endcase
        end

        default: ALUControlOut = 4'b1111;
    endcase
end

endmodule
