module ControlUnit(
    OPcode,
    func3,
    func7,
    branch,
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
output reg MemRead;
output reg MemtoReg;
output reg MemWrite;
output reg ALUScr;
output reg RegWrite;
output reg [3:0] ALUControlOut;

always @(*) begin
    // Safe defaults for unsupported instructions.
    branch = 1'b0;
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

        default: begin
            // Unsupported opcode: retain safe defaults.
        end

    endcase
end

endmodule