`timescale 1ns/1ps

module RegisterFile_tb;

  reg clk;
  reg reset;
  reg [4:0] Rs1;
  reg [4:0] Rs2;
  reg [4:0] Rd;
  reg [31:0] Write_data;
  reg RegWrite;
  wire [31:0] Read_data1;
  wire [31:0] Read_data2;

  Register_File dut (
    .clk(clk),
    .reset(reset),
    .Rs1(Rs1),
    .Rs2(Rs2),
    .Rd(Rd),
    .Write_data(Write_data),
    .RegWrite(RegWrite),
    .Read_data1(Read_data1),
    .Read_data2(Read_data2)
  );

  always #5 clk = ~clk;

  task check_read;
    input [4:0] rs1;
    input [31:0] expected1;
    input [4:0] rs2;
    input [31:0] expected2;
    begin
      Rs1 = rs1;
      Rs2 = rs2;
      #1;
      if (Read_data1 !== expected1 || Read_data2 !== expected2) begin
        $display("FAIL: x%0d=%h, expected %h; x%0d=%h, expected %h",
                 rs1, Read_data1, expected1, rs2, Read_data2, expected2);
        $fatal;
      end
    end
  endtask

  task write_register;
    input [4:0] rd;
    input [31:0] data;
    begin
      Rd = rd;
      Write_data = data;
      RegWrite = 1'b1;
      @(posedge clk);
      #1;
      RegWrite = 1'b0;
    end
  endtask

  initial begin
    clk = 1'b0;
    reset = 1'b1;
    Rs1 = 5'd0;
    Rs2 = 5'd0;
    Rd = 5'd0;
    Write_data = 32'd0;
    RegWrite = 1'b0;

    @(posedge clk);
    #1;
    reset = 1'b0;

    check_read(5'd0, 32'd0, 5'd31, 32'd0);

    write_register(5'd5, 32'h1234_5678);
    check_read(5'd5, 32'h1234_5678, 5'd0, 32'd0);

    write_register(5'd10, 32'hDEAD_BEEF);
    check_read(5'd5, 32'h1234_5678, 5'd10, 32'hDEAD_BEEF);

    write_register(5'd0, 32'hFFFF_FFFF);
    check_read(5'd0, 32'd0, 5'd5, 32'h1234_5678);

    $display("PASS: Register_File testbench completed successfully.");
    $finish;
  end

endmodule
