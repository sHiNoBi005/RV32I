`timescale 1ns / 1ns

module Top_tb;

    reg clk;
    reg reset;

    wire [31:0] PC_out;
    wire [31:0] instruction;
    wire [31:0] ALU_result;
    wire ALU_zero;
    wire [31:0] memory_read_data;
    wire [31:0] writeback_data;

    Top uut (
        .clk(clk),
        .reset(reset),
        .PC_out(PC_out),
        .instruction(instruction),
        .ALU_result(ALU_result),
        .ALU_zero(ALU_zero),
        .memory_read_data(memory_read_data),
        .writeback_data(writeback_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        $monitor(
            "time = %0t | pc = %h | instr = %h | rs1_data = %0d | rs2_data = %0d | alu_out = %0d | reg_write = %b",
            $time, PC_out, instruction,
            uut.Read_data1, uut.Read_data2,
            ALU_result, uut.RegWrite
        );

        // Let reset clear the register file before seeding source registers.
        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        uut.register_file.registers[1] = 32'd20;
        uut.register_file.registers[2] = 32'd3;

        #100;
        $finish;
    end

endmodule
