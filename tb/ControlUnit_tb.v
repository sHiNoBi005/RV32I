`timescale 1ns/1ps

module ControlUnit_tb;

  reg [6:0] OPcode;
  reg [2:0] func3;
  reg [6:0] func7;
  wire branch;
  wire MemRead;
  wire MemtoReg;
  wire MemWrite;
  wire ALUScr;
  wire RegWrite;
  wire [3:0] ALUControlOut;

  ControlUnit dut (
    .OPcode(OPcode),
    .func3(func3),
    .func7(func7),
    .branch(branch),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .MemWrite(MemWrite),
    .ALUScr(ALUScr),
    .RegWrite(RegWrite),
    .ALUControlOut(ALUControlOut)
  );

  task check_controls;
    input [6:0] opcode;
    input [2:0] funct3;
    input [6:0] funct7;
    input expected_branch;
    input expected_mem_read;
    input expected_mem_to_reg;
    input expected_mem_write;
    input expected_alu_src;
    input expected_reg_write;
    input [3:0] expected_alu_control;
    begin
      OPcode = opcode;
      func3 = funct3;
      func7 = funct7;
      #1;

      if (branch !== expected_branch ||
          MemRead !== expected_mem_read ||
          MemtoReg !== expected_mem_to_reg ||
          MemWrite !== expected_mem_write ||
          ALUScr !== expected_alu_src ||
          RegWrite !== expected_reg_write ||
          ALUControlOut !== expected_alu_control) begin
        $display("FAIL: opcode=%b func3=%b func7=%b", opcode, funct3, funct7);
        $display("  Expected: branch=%b MemRead=%b MemtoReg=%b MemWrite=%b ALUScr=%b RegWrite=%b ALUControl=%b",
                 expected_branch, expected_mem_read, expected_mem_to_reg,
                 expected_mem_write, expected_alu_src, expected_reg_write,
                 expected_alu_control);
        $display("  Actual:   branch=%b MemRead=%b MemtoReg=%b MemWrite=%b ALUScr=%b RegWrite=%b ALUControl=%b",
                 branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite,
                 ALUControlOut);
        $fatal;
      end
    end
  endtask

  initial begin
    $dumpfile("sim/ControlUnit.vcd");
    $dumpvars(0, ControlUnit_tb);

    // R-type instructions: no memory or branch activity, register write enabled.
    check_controls(7'b0110011, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0010); // ADD
    check_controls(7'b0110011, 3'b000, 7'b0100000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0110); // SUB
    check_controls(7'b0110011, 3'b111, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000); // AND
    check_controls(7'b0110011, 3'b110, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0001); // OR

    // Unsupported instruction encodings use safe defaults.
    check_controls(7'b0110011, 3'b001, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111);
    check_controls(7'b0000011, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111);

    $display("PASS: ControlUnit testbench completed successfully.");
    $finish;
  end

endmodule
