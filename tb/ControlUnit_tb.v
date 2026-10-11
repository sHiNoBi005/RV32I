`timescale 1ns/1ps

module ControlUnit_tb;

  reg [6:0] OPcode;
  reg [2:0] func3;
  reg [6:0] func7;
  wire branch;
  wire jump;
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
    .jump(jump),
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
        $display("FAIL: opcode=%b func3=%b func7=%b", opcode, funct3, func7);
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

    check_controls(7'b0110011, 3'b001, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0011); // SLL

    check_controls(7'b0110011, 3'b010, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0100); // SLT

    check_controls(7'b0110011, 3'b011, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0101); // SLTU

    check_controls(7'b0110011, 3'b100, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0111); // XOR

    check_controls(7'b0110011, 3'b101, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1000); // SRL

    check_controls(7'b0110011, 3'b101, 7'b0100000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b1001); // SRA

    check_controls(7'b0110011, 3'b110, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0001); // OR

    check_controls(7'b0110011, 3'b111, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000); // AND

    // I-type instructions: no memory or branch activity, register write enabled.
    check_controls(7'b0010011, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0010); // ADDI
                   
    // ADDI with immediate -1: upper immediate bits are all ones.
    check_controls(7'b0010011, 3'b000, 7'b1111111,
                   1'b0, 1'b0, 1'b0, 1'b0,1'b1, 1'b1, 4'b0010);

    check_controls(7'b0010011, 3'b001, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0011); // SLLI

    check_controls(7'b0010011, 3'b010, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0100); // SLTI

    check_controls(7'b0010011, 3'b011, 7'b0000000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0101); // SLTIU

    check_controls(7'b0010011, 3'b100, 7'b0000000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0111); // XORI

    check_controls(7'b0010011, 3'b101, 7'b0000000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b1000); // SRLI   

    check_controls(7'b0010011, 3'b101, 7'b0100000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b1001); // SRAI

    check_controls(7'b0010011, 3'b110, 7'b0000000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0001); // ORI

    check_controls(7'b0010011, 3'b111, 7'b0000000,
                    1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0000); // ANDI

    // Load instructions: read memory, select memory data, and write rd.
    // The ALU adds the base register and sign-extended immediate.
    check_controls(7'b0000011, 3'b000, 7'b0000000,
                   1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0010); // LB

    check_controls(7'b0000011, 3'b001, 7'b0000000,
                   1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0010); // LH

    check_controls(7'b0000011, 3'b010, 7'b0000000,
                   1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0010); // LW

    check_controls(7'b0000011, 3'b100, 7'b0000000,
                   1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0010); // LBU

    check_controls(7'b0000011, 3'b101, 7'b0000000,
                   1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 4'b0010); // LHU

    // Store instructions: no memory read or register write; calculate address with ADD.
    check_controls(7'b0100011, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 4'b0010); // SB

    check_controls(7'b0100011, 3'b001, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 4'b0010); // SH

    check_controls(7'b0100011, 3'b010, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 4'b0010); // SW

    // U-type instructions: no memory or branch activity; register write enabled.
    check_controls(7'b0110111, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0010); // LUI

    check_controls(7'b0010111, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0010); // AUIPC

    // Conditional branch instructions (B/SB format).
    // Branch condition evaluation/PC redirection will be integrated in Top later.
    check_controls(7'b1100011, 3'b000, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0110); // BEQ

    check_controls(7'b1100011, 3'b001, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0110); // BNE

    check_controls(7'b1100011, 3'b100, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0100); // BLT

    check_controls(7'b1100011, 3'b101, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0100); // BGE

    check_controls(7'b1100011, 3'b110, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0101); // BLTU

    check_controls(7'b1100011, 3'b111, 7'b0000000,
                   1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0101); // BGEU

    // Invalid branch funct3 retains safe defaults.
    check_controls(7'b1100011, 3'b010, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111);

    // UJ-format JAL: write a return address later in Top, and signal a jump.
    check_controls(7'b1101111, 3'b000, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 4'b0010); // JAL
    if (jump !== 1'b1) begin
      $display("FAIL: JAL should assert jump");
      $fatal;
    end

    // Unsupported instruction encodings use safe defaults.
    check_controls(7'b0110011, 3'b001, 7'b0100000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111);

    check_controls(7'b0000011, 3'b011, 7'b0000000,
                   1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b1111); // Invalid load funct3
    if (jump !== 1'b0) begin
      $display("FAIL: jump should be low for non-JAL instructions");
      $fatal;
    end

    $display("PASS: ControlUnit testbench completed successfully.");
    $finish;
  end

  initial begin
    $monitor("Time=%0t | OPcode=%b | func3=%b | func7=%b | branch=%b | MemRead=%b | MemtoReg=%b | MemWrite=%b | ALUScr=%b | RegWrite=%b | ALUControlOut=%b",
             $time, OPcode, func3, func7, branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite, ALUControlOut);
  end

endmodule
