module ProgramCounter(
  clk,
  reset,
  PC_in,
  PC_out
)

// Port Declarations
input clk, reset;
input [31:0] PC_in;
output [31:0] PC_out;

always @(posedge clk)begin
  if(reset)begin
    PC_out <= 32'b0;
  end
  else begin
    PC_out <= PC_in;
  end
end
endmodule