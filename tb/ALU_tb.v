`timescale 1ns/1ps

module ALU_tb;

    reg [31:0] A, B;
    reg [3:0] ALUControl_in;
    wire [31:0] ALU_result;
    wire zero;

    ALU dut (
        .A(A),
        .B(B),
        .zero(zero),
        .ALUControl_in(ALUControl_in),
        .ALU_result(ALU_result)
    );

    initial begin
        $dumpfile("sim/ALU.vcd");
        $dumpvars(0, ALU_tb);

        A = 32'd4;
        B = 32'd1;

        ALUControl_in = 4'b0010; #1; // ADD: 4 + 1 = 5
        if (ALU_result !== 32'd5   || zero !== 1'b0) $fatal(1, "ADD failed");

        ALUControl_in = 4'b0110; #1; // SUB: 4 - 1 = 3
        if (ALU_result !== 32'd3 || zero !== 1'b0) $fatal(1, "SUB failed");

        ALUControl_in = 4'b0011; #1; // SLL: 4 << 1 = 8
        if (ALU_result !== 32'd8 || zero !== 1'b0) $fatal(1, "SLL failed");

        ALUControl_in = 4'b0100; #1; // SLT: 4 < 1 = 0
        if (ALU_result !== 32'd0 || zero !== 1'b1) $fatal(1, "SLT failed");

        ALUControl_in = 4'b0101; #1; // SLTU: 4 < 1 = 0
        if (ALU_result !== 32'd0 || zero !== 1'b1) $fatal(1, "SLTU failed");

        ALUControl_in = 4'b0111; #1; // XOR: 4 ^ 1 = 5
        if (ALU_result !== 32'd5 || zero !== 1'b0) $fatal(1, "XOR failed");

        ALUControl_in = 4'b1000; #1; // SRL: 4 >> 1 = 2
        if (ALU_result !== 32'd2 || zero !== 1'b0) $fatal(1, "SRL failed");

        ALUControl_in = 4'b1001; #1; // SRA: 4 >>> 1 = 2
        if (ALU_result !== 32'd2 || zero !== 1'b0) $fatal(1, "SRA failed");

        ALUControl_in = 4'b0001; #1; // OR: 4 | 1 = 5
        if (ALU_result !== 32'd5 || zero !== 1'b0) $fatal(1, "OR failed");

        ALUControl_in = 4'b0000; #1; // AND: 4 & 1 = 0
        if (ALU_result !== 32'd0 || zero !== 1'b1) $fatal(1, "AND failed");

        ALUControl_in = 4'b1111; #1; // Invalid control: 0
        if (ALU_result !== 32'd0 || zero !== 1'b1) $fatal(1, "Default operation failed");

        $finish;
    end
    initial begin
        $monitor("Time=%0t | A=%d | B=%d | ALUControl_in=%b | ALU_result=%d | zero=%b",
                 $time, A, B, ALUControl_in, ALU_result, zero);
    end
endmodule