`timescale 1ns/1ps

module RegisterFile_tb;

  reg clk, reset, RegWrite;
  reg [4:0] Rs1, Rs2, Rd;
  reg [31:0] Write_data;
  wire [31:0] Read_data1, Read_data2;

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

  initial begin
    clk = 0;
    reset = 1;
    RegWrite = 0;
    Rs1 = 0;
    Rs2 = 0;
    Rd = 0;
    Write_data = 0;

    @(posedge clk);
    #1 reset = 0;

    // x0 always reads as zero.
    Rs1 = 0;
    #1 if (Read_data1 !== 0) $fatal(1, "x0 reset check failed");

    // Write and read one register.
    Rd = 5;
    Write_data = 32'h1234_5678;
    RegWrite = 1;
    @(posedge clk);
    #1 RegWrite = 0;
    Rs1 = 5;
    Rs2 = 0;
    #1 if (Read_data1 !== 32'h1234_5678 || Read_data2 !== 0)
      $fatal(1, "register read check failed");

    // Writes to x0 are ignored.
    Rd = 0;
    Write_data = 32'hFFFF_FFFF;
    RegWrite = 1;
    @(posedge clk);
    #1;
    if (Read_data2 !== 0) $fatal(1, "x0 write check failed");

    $display("PASS: Register_File testbench completed successfully.");
    $finish;
  end
  initial begin
    $monitor("Time=%0t | clk=%b | reset=%b | RegWrite=%b | Rs1=%d | Rs2=%d | Rd=%d | Write_data=%h | Read_data1=%h | Read_data2=%h",
             $time, clk, reset, RegWrite, Rs1, Rs2, Rd, Write_data, Read_data1, Read_data2);
  end

endmodule
