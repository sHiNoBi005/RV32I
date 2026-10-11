`timescale 1ns/1ps

module Top_tb;

    reg clk = 0;
    reg reset = 1;

    wire [31:0] PC_out;
    wire [31:0] instruction;
    wire [31:0] ALU_result;
    wire zero;

    integer i;

    Top dut (
        .clk(clk),
        .reset(reset),
        .PC_out(PC_out),
        .instruction(instruction),
        .ALU_result(ALU_result),
        .zero(zero)
    );

    always #5 clk = ~clk;

    task check_register;
        input integer register_number;
        input [31:0] expected;
        input [127:0] instruction_name;
        begin
            if (dut.register_file.registers[register_number] !== expected)
                $fatal(1, "%0s failed: x%0d = %h, expected %h",
                       instruction_name, register_number,
                       dut.register_file.registers[register_number], expected);
            $display("%0s passed", instruction_name);
        end
    endtask

    task check_memory;
        input integer word_number;
        input [31:0] expected;
        input [127:0] instruction_name;
        begin
            if (dut.data_memory.memory[word_number] !== expected)
                $fatal(1, "%0s failed: memory[%0d] = %h, expected %h",
                       instruction_name, word_number,
                       dut.data_memory.memory[word_number], expected);
            $display("%0s passed", instruction_name);
        end
    endtask

    initial begin
        $dumpfile("sim/Top.vcd");
        $dumpvars(0, Top_tb);

        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        // Seed registers used by the instruction memory program.
        dut.register_file.registers[1] = 32'd20;
        dut.register_file.registers[2] = 32'd3;
        dut.register_file.registers[14] = 32'h80000000;
        dut.register_file.registers[15] = 32'd1;
        dut.register_file.registers[16] = 32'h00000080;
        dut.register_file.registers[17] = 32'hFFFF80FF;

        // Execute all 36 instruction slots in programs/instructions.mem.
        for (i = 0; i < 36; i = i + 1) begin
            @(posedge clk);
            #1;

            case (i)
                0:  check_register(3, 32'd23, "ADD");
                1:  check_register(4, 32'd17, "SUB");
                2:  check_register(5, 32'd160, "SLL");
                3:  check_register(6, 32'd1, "SLT");
                4:  check_register(7, 32'd1, "SLTU");
                5:  check_register(8, 32'd23, "XOR");
                6:  check_register(9, 32'd2, "SRL");
                7:  check_register(10, 32'hC0000000, "SRA");
                8:  check_register(11, 32'd23, "OR");
                9:  check_register(12, 32'd0, "AND");
                10: check_memory(5, 32'd3, "SW");
                11: check_register(13, 32'd3, "LW");
                12: check_memory(5, 32'h00008003, "SB");
                13: check_register(13, 32'hFFFFFF80, "LB");
                14: check_register(13, 32'h00000080, "LBU");
                15: check_memory(5, 32'h80FF8003, "SH");
                16: check_register(13, 32'hFFFF80FF, "LH");
                17: check_register(13, 32'h000080FF, "LHU");
                18: check_register(13, 32'h80FF8003, "LW");
                19: check_register(18, 32'h12345000, "LUI");
                20: check_register(19, 32'h00002050, "AUIPC");
                23: check_register(21, 32'd7, "BEQ target ADDI");
                25: check_register(22, 32'd9, "BNE not taken");
                28: check_register(24, 32'd11, "BLT target ADDI");
                30: check_register(25, 32'd12, "BGE not taken");
                32: check_register(26, 32'd13, "BLTU not taken");
                35: check_register(28, 32'd15, "BGEU target ADDI");
            endcase

            $display("Instruction %0d: PC=%h, instruction=%h",
                     i, PC_out, instruction);
        end

        // These instructions must have been skipped by taken branches.
        check_register(20, 32'd0, "BEQ skipped ADDI");
        check_register(23, 32'd0, "BLT skipped ADDI");
        check_register(27, 32'd0, "BGEU skipped ADDI");

        $display("PASS: Complete integration program passed.");
        $finish;
    end

endmodule
