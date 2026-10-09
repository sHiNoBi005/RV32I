`timescale 1ns/1ps

module ALUControl_tb;

  reg [2:0] func3;
  reg [6:0] func7;
  reg [1:0] ALUOp;
  wire [3:0] ALUControlOut;

  ALUControl dut (
    .func3(func3),
    .func7(func7),
    .ALUOp(ALUOp),
    .ALUControlOut(ALUControlOut)
  );

  task check_control;
    input [1:0] alu_op;
    input [6:0] funct7;
    input [2:0] funct3;
    input [3:0] expected;
    begin
      ALUOp = alu_op;
      func7 = funct7;
      func3 = funct3;
      #1;
      if (ALUControlOut !== expected) begin
        $display("FAIL: ALUOp=%b func7=%b func3=%b returned %b, expected %b",
                 alu_op, funct7, funct3, ALUControlOut, expected);
        $fatal;
      end
    end
  endtask

  initial begin
    $dumpfile("ALUControl.vcd");
    $dumpvars(0, ALUControl_tb);

    ALUOp = 2'b00;
    func7 = 7'b0;
    func3 = 3'b0;

    // ALUOp 00: ADD for memory address calculation.
    check_control(2'b00, 7'bxxxxxxx, 3'bxxx, 4'b0010);

    // ALUOp 01: SUB for branch comparison.
    check_control(2'b01, 7'bxxxxxxx, 3'bxxx, 4'b0110);

    // ALUOp 10: R-type operations.
    check_control(2'b10, 7'b0000000, 3'b000, 4'b0010); // ADD
    check_control(2'b10, 7'b0100000, 3'b000, 4'b0110); // SUB
    check_control(2'b10, 7'b0000000, 3'b111, 4'b0000); // AND
    check_control(2'b10, 7'b0000000, 3'b110, 4'b0001); // OR

    // Unsupported R-type and ALUOp combinations.
    check_control(2'b10, 7'b0000000, 3'b001, 4'b1111);
    check_control(2'b11, 7'b0000000, 3'b000, 4'b1111);

    $display("PASS: ALUControl testbench completed successfully.");
    $finish;
  end

endmodule
