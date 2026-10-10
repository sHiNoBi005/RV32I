module Register_File(
  clk,
  reset,
  Rs1,
  Rs2,
  Rd,
  Write_data,
  RegWrite,
  Read_data1,
  Read_data2
);

input clk, reset, RegWrite; //these inputs are single bit inputs
input [19:15] Rs1; //5 bit input for first source register
input [24:20] Rs2; //5 bit input for second source register
input [11:7] Rd; //5 bit input for destination register
input [31:0] Write_data; //32 bit input for data to be written to destination register

output wire [31:0] Read_data1, Read_data2; //32 bit outputs for data read from source registers

reg [31:0] registers [31:0]; //32 registers of 32 bits each
integer i;

assign Read_data1 = (Rs1 == 5'd0) ? 32'b0 : registers[Rs1]; //x0 is hardwired to zero
assign Read_data2 = (Rs2 == 5'd0) ? 32'b0 : registers[Rs2]; //x0 is hardwired to zero

always @(posedge clk) begin
  if(reset == 1'b1)begin
    for(i = 0; i < 32; i++)begin
      registers[i] <= 32'b0; //resetting all registers to 0
    end
  end
  else if(RegWrite == 1'b1 && Rd != 5'd0)begin
    registers[Rd] <= Write_data; //writing data to the destination register if RegWrite is high
  end
end
endmodule
