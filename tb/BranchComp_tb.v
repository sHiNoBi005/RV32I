`timescale 1ns/1ps

module BranchComp_tb;

  reg [31:0] rs1_data;
  reg [31:0] rs2_data;
  reg [2:0] func3;
  wire br_taken;

  BranchComp dut (
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .func3(func3),
    .br_taken(br_taken)
  );

  task check_branch;
    input [160*8-1:0] test_name;
    input [31:0] value1;
    input [31:0] value2;
    input [2:0] branch_func3;
    input expected;
    begin
      rs1_data = value1;
      rs2_data = value2;
      func3 = branch_func3;
      #1;

      if (br_taken !== expected) begin
        $display("FAIL: %0s | rs1=%h rs2=%h func3=%b got=%b expected=%b",
                 test_name, value1, value2, branch_func3, br_taken, expected);
        $fatal;
      end
      else begin
        $display("PASS: %0s", test_name);
      end
    end
  endtask

  initial begin
    $dumpfile("BranchComp.vcd");
    $dumpvars(0, BranchComp_tb);

    // BEQ and BNE
    check_branch("BEQ true", 32'd10, 32'd10, 3'b000, 1'b1);
    check_branch("BEQ false", 32'd10, 32'd20, 3'b000, 1'b0);
    check_branch("BNE true", 32'd10, 32'd20, 3'b001, 1'b1);
    check_branch("BNE false", 32'd10, 32'd10, 3'b001, 1'b0);

    // Signed comparisons
    check_branch("BLT true: -1 < 1", 32'hFFFFFFFF, 32'd1, 3'b100, 1'b1);
    check_branch("BLT false: 2 < 1", 32'd2, 32'd1, 3'b100, 1'b0);
    check_branch("BGE true: 2 >= -1", 32'd2, 32'hFFFFFFFF, 3'b101, 1'b1);
    check_branch("BGE false: -1 >= 1", 32'hFFFFFFFF, 32'd1, 3'b101, 1'b0);

    // Unsigned comparisons
    check_branch("BLTU true: 1 < max", 32'd1, 32'hFFFFFFFF, 3'b110, 1'b1);
    check_branch("BLTU false: max < 1", 32'hFFFFFFFF, 32'd1, 3'b110, 1'b0);
    check_branch("BGEU true: max >= 1", 32'hFFFFFFFF, 32'd1, 3'b111, 1'b1);
    check_branch("BGEU false: 1 >= max", 32'd1, 32'hFFFFFFFF, 3'b111, 1'b0);

    // Invalid branch funct3 must never take a branch.
    check_branch("Invalid funct3", 32'd10, 32'd10, 3'b010, 1'b0);

    $display("PASS: All BranchComp tests completed successfully.");
    $finish;
  end

endmodule
