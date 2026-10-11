
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
        // Seed memory for the SW and LW integration tests.
        dut.register_file.registers[16] = 32'h00000080;
        dut.register_file.registers[17] = 32'hFFFF80FF;

        // Allow each instruction to execute and write back.
        for (i = 0; i < 19; i = i + 1) begin
            @(posedge clk);
            #1;

            case (i)
                0: begin
                    if (dut.register_file.registers[3] !== 32'd23)
                        $fatal(1, "ADD failed");
                end

                1: begin
                    if (dut.register_file.registers[4] !== 32'd17)
                        $fatal(1, "SUB failed");
                end

                2: begin
                    if (dut.register_file.registers[5] !== 32'd160)
                        $fatal(1, "SLL failed");
                end

                3: begin
                    if (dut.register_file.registers[6] !== 32'd1)
                        $fatal(1, "SLT failed");
                end

                4: begin
                    if (dut.register_file.registers[7] !== 32'd1)
                        $fatal(1, "SLTU failed");
                end

                5: begin
                    if (dut.register_file.registers[8] !== 32'd23)
                        $fatal(1, "XOR failed");
                end

                6: begin
                    if (dut.register_file.registers[9] !== 32'd2)
                        $fatal(1, "SRL failed");
                end

                7: begin
                    if (dut.register_file.registers[10] !== 32'hC0000000)
                        $fatal(1, "SRA failed");
                end

                8: begin
                    if (dut.register_file.registers[11] !== 32'd23)
                        $fatal(1, "OR failed");
                end

                9: begin
                    if (dut.register_file.registers[12] !== 32'd0)
                        $fatal(1, "AND failed");
                end

                10: begin
                    if (dut.data_memory.memory[5] !== 32'd3)
                        $fatal(1, "SW integration test failed");
                    $display("SW integration test passed");
                end

                11: begin
                    if (dut.register_file.registers[13] !== 32'd3)
                        $fatal(1, "LW integration test failed: x13 = %h",
                               dut.register_file.registers[13]);
                    $display("LW integration test passed");
                end

                12: begin
                     if (dut.data_memory.memory[5] !== 32'h00008003)
                         $fatal(1, "SB integration test failed: memory = %h",
                                dut.data_memory.memory[5]);
                     $display("SB integration test passed");
                end

                13: begin
                     if (dut.register_file.registers[13] !== 32'hFFFFFF80)
                         $fatal(1, "LB sign extension failed: x13 = %h",
                                dut.register_file.registers[13]);
                     $display("LB integration test passed");
                 end

                 14: begin
                     if (dut.register_file.registers[13] !== 32'h00000080)
                         $fatal(1, "LBU zero extension failed: x13 = %h",
                                dut.register_file.registers[13]);
                     $display("LBU integration test passed");
                 end

                 15: begin
                     if (dut.data_memory.memory[5] !== 32'h80FF8003)
                         $fatal(1, "SH integration test failed: memory = %h",
                                dut.data_memory.memory[5]);
                     $display("SH integration test passed");
                 end

                 16: begin
                     if (dut.register_file.registers[13] !== 32'hFFFF80FF)
                         $fatal(1, "LH sign extension failed: x13 = %h",
                                dut.register_file.registers[13]);
                     $display("LH integration test passed");
                 end

                 17: begin
                     if (dut.register_file.registers[13] !== 32'h000080FF)
                         $fatal(1, "LHU zero extension failed: x13 = %h",
                                dut.register_file.registers[13]);
                     $display("LHU integration test passed");
                 end

                 18: begin
                     if (dut.register_file.registers[13] !== 32'h80FF8003)
                         $fatal(1, "Final LW failed: x13 = %h",
                                dut.register_file.registers[13]);
                     $display("Final LW integration test passed");
                 end

            endcase

            $display("Instruction %0d passed: PC=%h, instruction=%h",
                     i, PC_out, instruction);
        end

        $display("PASS: All 18 integration tests passed.");
        $finish;
    end

endmodule
