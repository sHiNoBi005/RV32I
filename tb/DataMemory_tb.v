`timescale 1ns/1ps

module DataMemory_tb;

  reg clk, reset, MemWrite, MemRead;
  reg [31:0] address, write_data;
  wire [31:0] read_data;
  reg [2:0] func3;

  Data_Memory dut (
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .address(address),
    .write_data(write_data),
    .read_data(read_data),
    .func3(func3)
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
    func3 = 3'b000;

    @(posedge clk);
    #1 reset = 0;

    address = 32'd4;
    write_data = 32'h80FF7F01;
    MemWrite = 1;
    @(posedge clk);
    #1 MemWrite = 0;

    MemRead = 1;
    #1 address = 32'd7;
    func3 = 3'b000; #1;
    if (read_data !== 32'hFFFFFF80) $fatal(1, "LB failed");

    func3 = 3'b100; #1;
    if (read_data !== 32'h00000080) $fatal(1, "LBU failed");

    address = 32'd6;
    func3 = 3'b001; #1;
    if (read_data !== 32'hFFFF80FF) $fatal(1, "LH failed");

    func3 = 3'b101; #1;
    if (read_data !== 32'h000080FF) $fatal(1, "LHU failed");

    address = 32'd4;
    func3 = 3'b010; #1;
    if (read_data !== 32'h80FF7F01) $fatal(1, "LW failed");

    MemRead = 0;
    #1 if (read_data !== 0) $fatal(1, "disabled read failed");

    $display("PASS: Data_Memory testbench completed successfully.");
    $finish;
  end
  initial begin
    $monitor("Time: %0t | MemRead: %b | MemWrite: %b | Address: %h | WriteData: %h | ReadData: %h | Func3: %b",
             $time, MemRead, MemWrite, address, write_data, read_data, func3);
  end
endmodule
