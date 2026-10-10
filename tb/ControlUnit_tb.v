`timescale 1ns/1ps

module ControlUnit_tb;

  reg [6:0] OPcode;
  wire branch;
  wire MemRead;
  wire MemtoReg;
  wire MemWrite;
  wire ALUScr;
  wire RegWrite;
  wire [1:0] ALUOp_out;

  ControlUnit dut (
    .OPcode(OPcode),
    .branch(branch),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .MemWrite(MemWrite),
    .ALUScr(ALUScr),
    .RegWrite(RegWrite),
    .ALUOp_out(ALUOp_out)
  );

  task check_controls;
    input [6:0] opcode;
    input expected_branch;
    input expected_memread;
    input expected_memtoreg;
    input expected_memwrite;
    input expected_aluscr;
    input expected_regwrite;
    input [1:0] expected_aluop;
    begin
      OPcode = opcode;
      #1;
      if ({branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite, ALUOp_out}
          !== {expected_branch, expected_memread, expected_memtoreg,
               expected_memwrite, expected_aluscr, expected_regwrite,
               expected_aluop}) begin
        $display("FAIL: opcode=%b controls=%b expected=%b",
                 opcode,
                 {branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite, ALUOp_out},
                 {expected_branch, expected_memread, expected_memtoreg,
                  expected_memwrite, expected_aluscr, expected_regwrite,
                  expected_aluop});
        $fatal(1);
      end
    end
  endtask

  initial begin
    $dumpfile("ControlUnit.vcd");
    $dumpvars(0, ControlUnit_tb);

    // R-type register-register instructions.
    check_controls(7'b0110011, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b10);

    // I-type ALU-immediate instructions.
    check_controls(7'b0010011, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10);

    // Loads.
    check_controls(7'b0000011, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 2'b00);

    // Stores.
    check_controls(7'b0100011, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 2'b00);

    // Conditional branches.
    check_controls(7'b1100011, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b01);

    // Unsupported opcode returns safe defaults (no latches).
    check_controls(7'b1111111, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b11);

    $display("PASS: ControlUnit opcode decode testbench completed.");
    $finish;
  end

endmodule
