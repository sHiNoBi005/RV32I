`timescale 1ns / 1ns

module Top_tb;

    reg clk;
    reg reset;

    Top uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        $monitor(
            "time = %0t | pc = %h | instr = %h | rs1_data = %0d | rs2_data = %0d | alu_out = %0d | reg_write = %b",
            $time, uut.PC_out, uut.instruction,
            uut.Read_data1, uut.Read_data2,
            uut.ALU_result, uut.RegWrite
        );

        // Release reset after two clock edges.
        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        // Initialize registers used by the sample program.
        uut.register_file.registers[1]  = 32'd20;
        uut.register_file.registers[2]  = 32'd3;
        uut.register_file.registers[14] = 32'h80000000;
        uut.register_file.registers[15] = 32'd1;
        uut.register_file.registers[16] = 32'h00000080;
        uut.register_file.registers[17] = 32'hFFFF80FF;

        // Run until the final JALR instruction is executed.
        wait (uut.PC_out == 32'd144);
        @(posedge clk);
        #1;
        $finish;
    end

endmodule
