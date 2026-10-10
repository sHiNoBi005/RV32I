`timescale 1ns/1ps

module DataMemory_tb;

  reg clk, reset, MemWrite, MemRead;
  reg [31:0] address, write_data;
  wire [31:0] read_data;

  Data_Memory dut (
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .address(address),
    .write_data(write_data),
    .read_data(read_data)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/DataMemory.vcd");
    $dumpvars(0, DataMemory_tb);

    clk = 0;
    reset = 1;
    MemWrite = 0;
    MemRead = 0;
    address = 0;
    write_data = 0;

    @(posedge clk);
    #1 reset = 0;

    address = 32'd4;
    write_data = 32'h1234_5678;
    MemWrite = 1;
    @(posedge clk);
    #1 MemWrite = 0;

    MemRead = 1;
    #1 if (read_data !== 32'h1234_5678) $fatal(1, "memory read failed");

    MemRead = 0;
    #1 if (read_data !== 0) $fatal(1, "disabled read failed");

    $display("PASS: Data_Memory testbench completed successfully.");
    $finish;
  end

endmodule
