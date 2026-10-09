`timescale 1ns/1ps

module DataMemory_tb;

  reg clk;
  reg reset;
  reg MemWrite;
  reg MemRead;
  reg [31:0] address;
  reg [31:0] write_data;
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

  task check_read;
    input [31:0] addr;
    input [31:0] expected;
    begin
      address = addr;
      MemRead = 1'b1;
      #1;
      if (read_data !== expected) begin
        $display("FAIL: address %h returned %h, expected %h",
                 addr, read_data, expected);
        $fatal;
      end
      MemRead = 1'b0;
    end
  endtask

  task write_memory;
    input [31:0] addr;
    input [31:0] data;
    begin
      address = addr;
      write_data = data;
      MemWrite = 1'b1;
      @(posedge clk);
      #1;
      MemWrite = 1'b0;
    end
  endtask

  initial begin
    $dumpfile("DataMemory.vcd");
    $dumpvars(0, DataMemory_tb);

    clk = 1'b0;
    reset = 1'b1;
    MemWrite = 1'b0;
    MemRead = 1'b0;
    address = 32'b0;
    write_data = 32'b0;

    // Reset is synchronous, so hold it through one rising edge.
    @(posedge clk);
    #1;
    reset = 1'b0;

    // Reset memory should read as zero.
    check_read(32'h0000_0000, 32'h0000_0000);
    check_read(32'h0000_03FC, 32'h0000_0000);

    // Verify writes at two word-aligned byte addresses.
    write_memory(32'h0000_0000, 32'h1234_5678);
    write_memory(32'h0000_0004, 32'hDEAD_BEEF);
    check_read(32'h0000_0000, 32'h1234_5678);
    check_read(32'h0000_0004, 32'hDEAD_BEEF);

    // Verify the last word in the 256-word memory.
    write_memory(32'h0000_03FC, 32'hCAFE_BABE);
    check_read(32'h0000_03FC, 32'hCAFE_BABE);

    // Read output must be zero when MemRead is disabled.
    address = 32'h0000_0000;
    MemRead = 1'b0;
    #1;
    if (read_data !== 32'h0000_0000) begin
      $display("FAIL: read_data was %h while MemRead was disabled",
               read_data);
      $fatal;
    end

    $display("PASS: Data_Memory testbench completed successfully.");
    $finish;
  end

endmodule
