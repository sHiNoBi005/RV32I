
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

    initial begin
        $dumpfile("sim/Top.vcd");
        $dumpvars(0, Top_tb);

        // Allow reset to initialize the processor.
        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        // Seed registers for this R-type integration test.
        dut.register_file.registers[1] = 32'd20;
        dut.register_file.registers[2] = 32'd3;
        dut.register_file.registers[14] = 32'h80000000;
        dut.register_file.registers[15] = 32'd1;

        // Allow each instruction to execute and write back.
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            #1;

            case (i)
                0: if (dut.register_file.registers[3] !== 32'd23)
                       $fatal(1, "ADD failed");

                1: if (dut.register_file.registers[4] !== 32'd17)
                       $fatal(1, "SUB failed");

                2: if (dut.register_file.registers[5] !== 32'd160)
                       $fatal(1, "SLL failed");

                3: if (dut.register_file.registers[6] !== 32'd1)
                       $fatal(1, "SLT failed");

                4: if (dut.register_file.registers[7] !== 32'd1)
                       $fatal(1, "SLTU failed");

                5: if (dut.register_file.registers[8] !== 32'd23)
                       $fatal(1, "XOR failed");

                6: if (dut.register_file.registers[9] !== 32'd2)
                       $fatal(1, "SRL failed");

                7: if (dut.register_file.registers[10] !== 32'hC0000000)
                       $fatal(1, "SRA failed");

                8: if (dut.register_file.registers[11] !== 32'd23)
                       $fatal(1, "OR failed");

                9: if (dut.register_file.registers[12] !== 32'd0)
                       $fatal(1, "AND failed");
            endcase

            $display("Instruction %0d passed: PC=%h, instruction=%h",
                     i, PC_out, instruction);
        end

        $display("PASS: All ten R-type integration tests passed.");
        $finish;
    end

endmodule
