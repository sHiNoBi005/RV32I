`timescale 1ns/1ps

module ALU_tb;

    reg [31:0] A;
    reg [31:0] B;
    reg [3:0] ALUControl_in;

    wire [31:0] ALU_result;
    wire zero;

    // Instantiate the ALU
    ALU dut (
        .A(A),
        .B(B),
        .zero(zero),
        .ALUControl_in(ALUControl_in),
        .ALU_result(ALU_result)
    );

    // Task to check the ALU result
    task check_result;
        input [3:0] control;
        input [31:0] operand_a;
        input [31:0] operand_b;
        input [31:0] expected_result;
        input expected_zero;
        begin
            ALUControl_in = control;
            A = operand_a;
            B = operand_b;
            #10;

            if (ALU_result !== expected_result || zero !== expected_zero) begin
                $display("FAIL: control=%b A=%h B=%h", control, operand_a, operand_b);
                $display("  Expected result=%h zero=%b", expected_result, expected_zero);
                $display("  Actual   result=%h zero=%b", ALU_result, zero);
            end
            else begin
                $display("PASS: control=%b A=%h B=%h result=%h zero=%b",
                         control, operand_a, operand_b, ALU_result, zero);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/ALU.vcd");
        $dumpvars(0, ALU_tb);

        // AND: 0xF0 & 0xCC = 0xC0
        check_result(4'b0000, 32'h000000F0, 32'h000000CC,
                     32'h000000C0, 1'b0);

        // OR: 0xF0 | 0x0C = 0xFC
        check_result(4'b0001, 32'h000000F0, 32'h0000000C,
                     32'h000000FC, 1'b0);

        // ADD: 10 + 5 = 15
        check_result(4'b0010, 32'd10, 32'd5,
                     32'd15, 1'b0);

        // ADD: test a result of zero
        check_result(4'b0010, 32'd0, 32'd0,
                     32'd0, 1'b0);

        // SUB: 10 - 5 = 5
        check_result(4'b0110, 32'd10, 32'd5,
                     32'd5, 1'b0);

        // SUB: equal operands produce zero result
        check_result(4'b0110, 32'd7, 32'd7,
                     32'd0, 1'b0);

        // SUB: test unsigned wraparound
        check_result(4'b0110, 32'd3, 32'd5,
                     32'hFFFFFFFE, 1'b0);

        // Default operation: result should equal A
        check_result(4'b1111, 32'h12345678, 32'h00000001,
                     32'h12345678, 1'b0);

        $display("ALU testbench completed.");
        $finish;
    end

endmodule