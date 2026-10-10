`timescale 1ns/1ps

module ALUControl_tb;

  reg [6:0] OPcode;
  reg [2:0] func3;
  reg [6:0] func7;
  wire [3:0] ALUControlOut;

  ALUControl dut (
    .OPcode(OPcode),
    .func3(func3),
    .func7(func7),
    .ALUControlOut(ALUControlOut)
  );

  task check_control;
    input [6:0] opcode;
    input [2:0] funct3;
    input [6:0] funct7;
    input [3:0] expected;
    begin
      OPcode = opcode;
      func3 = funct3;
      func7 = funct7;
      #1;
      if (ALUControlOut !== expected) begin
        $display("FAIL: opcode=%b funct3=%b funct7=%b returned %b, expected %b",
                 opcode, funct3, funct7, ALUControlOut, expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    $dumpfile("ALUControl.vcd");
    $dumpvars(0, ALUControl_tb);

    // R-type: opcode -> funct3 -> funct7.
    check_control(7'b0110011, 3'b000, 7'b0000000, 4'b0010); // ADD
    check_control(7'b0110011, 3'b000, 7'b0100000, 4'b0110); // SUB
    check_control(7'b0110011, 3'b111, 7'b0000000, 4'b0000); // AND
    check_control(7'b0110011, 3'b110, 7'b0000000, 4'b0001); // OR

    // Unknown/unsupported R-type function combinations.
    check_control(7'b0110011, 3'b000, 7'b0000001, 4'b1111);
    check_control(7'b0110011, 3'b001, 7'b0000000, 4'b1111);
    check_control(7'b0110011, 3'b111, 7'b0100000, 4'b1111);

    // I-type ALU-immediate instructions.
    check_control(7'b0010011, 3'b000, 7'b0000000, 4'b0010); // ADDI
    check_control(7'b0010011, 3'b111, 7'b0000000, 4'b0000); // ANDI
    check_control(7'b0010011, 3'b110, 7'b0000000, 4'b0001); // ORI
    check_control(7'b0010011, 3'b001, 7'b0000000, 4'b1111); // unsupported

    // Load/store effective address calculation.
    check_control(7'b0000011, 3'b010, 7'b0000000, 4'b0010); // LOAD
    check_control(7'b0100011, 3'b010, 7'b0000000, 4'b0010); // STORE

    // Supported branches use subtraction for comparison.
    check_control(7'b1100011, 3'b000, 7'b0000000, 4'b0110); // BEQ
    check_control(7'b1100011, 3'b001, 7'b0000000, 4'b0110); // BNE
    check_control(7'b1100011, 3'b100, 7'b0000000, 4'b1111); // unsupported branch

    // Unsupported opcode must retain the safe default.
    check_control(7'b1111111, 3'b000, 7'b0000000, 4'b1111);

    $display("PASS: ALUControl opcode/funct3/funct7 testbench completed.");
    $finish;
  end

endmodule
