module Data_Memory(
  clk,
  reset,
  MemWrite,
  MemRead,
  address,
  write_data,
  read_data
);

input clk, reset, MemWrite, MemRead;
input [31:0] address, write_data;

output wire [31:0] read_data;

reg [31:0] memory [0:255]; // 256 words of 32 bits each
integer i;

assign read_data = (MemRead) ? memory[address[9:2]] : 32'b0;

always @(posedge clk)begin
  if(reset == 1'b1)begin
    for(i = 0; i < 256; i++)begin
      memory[i] <= 32'b0;
    end
  end
  else if(MemWrite == 1'b1)begin
    memory[address[9:2]] <= write_data;
  end
end
endmodule