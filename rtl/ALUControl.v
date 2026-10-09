module ALUControl(
  func3,
  func7,
  ALUOp,
  ALUControlOut
);

input [14:12] func3;
input [31:25] func7;
input [1:0] ALUOp;

output reg [3:0] ALUControlOut;

always @(*)begin
  ALUControlOut = 4'b1111; // default value for ALUControlOut

  case (ALUOp)
    2'b00: ALUControlOut = 4'b0010; // add
    2'b01: ALUControlOut = 4'b0110; // sub
    2'b10: begin
      case ({func7, func3})
        10'b0000000_000: ALUControlOut = 4'b0010; // add
        10'b0100000_000: ALUControlOut = 4'b0110; // sub
        10'b0000000_111: ALUControlOut = 4'b0000; // and
        10'b0000000_110: ALUControlOut = 4'b0001; // or
        default: ALUControlOut = 4'b1111;
      endcase
    end
    default: ALUControlOut = 4'b1111;
  endcase
end
endmodule 
    