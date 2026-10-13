`timescale 1ns/1ps

// End-to-end testbench for Top_Rebuild.
// Instructions are fetched from programs/instructions.mem by InstructionMemory.
// Run the simulator from the repository root so that this relative path resolves.
module Top_tb;

    reg clk = 1'b0;
    reg reset = 1'b1;

    wire [31:0] PC_out;
    wire [31:0] instruction;
    wire [31:0] ALU_result;
    wire ALU_zero;
    wire [31:0] memory_read_data;
    wire [31:0] writeback_data;

    reg [31:0] expected_pc [0:33];
    reg [31:0] expected_next_pc;
    integer i;

    Top dut (
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

    // Continuously display key datapath signals while the test runs.
    initial begin
        $monitor(
            "time=%0t | PC=%h | instr=%h | rs1_data=%0d | rs2_data=%0d | ALU=%0d | reg_write=%b",
            $time, PC_out, instruction,
            dut.Read_data1, dut.Read_data2,
            ALU_result, dut.RegWrite
        );
    end

    task check_register;
        input integer register_number;
        input [31:0] expected_value;
        input string description;
        begin
            if (dut.register_file.registers[register_number] !== expected_value) begin
                $fatal(1,
                    "FAIL: %0s: x%0d=%h, expected %h",
                    description, register_number,
                    dut.register_file.registers[register_number], expected_value);
            end
            $display("PASS: %0s", description);
        end
    endtask

    task check_memory;
        input integer word_number;
        input [31:0] expected_value;
        input string description;
        begin
            if (dut.data_memory.memory[word_number] !== expected_value) begin
                $fatal(1,
                    "FAIL: %0s: memory[%0d]=%h, expected %h",
                    description, word_number,
                    dut.data_memory.memory[word_number], expected_value);
            end
            $display("PASS: %0s", description);
        end
    endtask

    initial begin
        $dumpfile("sim/Top.vcd");
        $dumpvars(0, Top_tb);

        // Expected program-counter sequence for the program in instructions.mem.
        // Taken branches skip the instructions at byte addresses 88, 108, and 136.
        for (i = 0; i <= 20; i = i + 1)
            expected_pc[i] = i * 4;

        expected_pc[21] = 32'd84;   // BEQ, taken
        expected_pc[22] = 32'd92;   // BEQ target: ADDI x21, x0, 36
        expected_pc[23] = 32'd96;   // BNE, not taken
        expected_pc[24] = 32'd100;  // ADDI x22, x0, 9
        expected_pc[25] = 32'd104;  // BLT, taken
        expected_pc[26] = 32'd112;  // BLT target: ADDI x24, x0, 11
        expected_pc[27] = 32'd116;  // BGE, not taken
        expected_pc[28] = 32'd120;  // ADDI x25, x0, 12
        expected_pc[29] = 32'd124;  // BLTU, not taken
        expected_pc[30] = 32'd128;  // ADDI x26, x0, 13
        expected_pc[31] = 32'd132;  // BGEU, taken
        expected_pc[32] = 32'd140;  // BGEU target: ADDI x28, x0, 15
        expected_pc[33] = 32'd144;  // JALR

        // Reset PC, register file, and data memory.
        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        // Seed only the source registers required by the test program.
        // Destination registers are updated by the processor itself.
        dut.register_file.registers[1]  = 32'd20;
        dut.register_file.registers[2]  = 32'd3;
        dut.register_file.registers[14] = 32'h80000000;
        dut.register_file.registers[15] = 32'd1;
        dut.register_file.registers[16] = 32'h00000080;
        dut.register_file.registers[17] = 32'hFFFF80FF;

        // Execute every reachable instruction up through the JALR.
        // The instruction words themselves are not duplicated here: they
        // come from programs/instructions.mem through InstructionMemory.
        for (i = 0; i < 34; i = i + 1) begin
            #1;

            if (PC_out !== expected_pc[i]) begin
                $fatal(1,
                    "FAIL: step %0d expected PC=%h, got %h",
                    i, expected_pc[i], PC_out);
            end

            if (i == 33)
                expected_next_pc = 32'd36; // JALR target x21 + 0
            else
                expected_next_pc = expected_pc[i+1];

            if (dut.PC_next !== expected_next_pc) begin
                $fatal(1,
                    "FAIL: at PC=%h expected PC_next=%h, got %h",
                    PC_out, expected_next_pc, dut.PC_next);
            end

            $display("STEP %0d: PC=%h INST=%h ALU=%h WB=%h NEXT=%h",
                i, PC_out, instruction, ALU_result,
                writeback_data, dut.PC_next);

            // Commit this instruction on the rising clock edge.
            @(posedge clk);
            #1;

            if (PC_out !== expected_next_pc) begin
                $fatal(1,
                    "FAIL: after clock expected PC=%h, got %h",
                    expected_next_pc, PC_out);
            end

            // Check architectural state after each instruction commits.
            case (expected_pc[i])
                32'd0:   check_register(3, 32'd23, "ADD x3");
                32'd4:   check_register(4, 32'd17, "SUB x4");
                32'd8:   check_register(5, 32'd160, "SLL x5");
                32'd12:  check_register(6, 32'd1, "SLT x6");
                32'd16:  check_register(7, 32'd1, "SLTU x7");
                32'd20:  check_register(8, 32'd23, "XOR x8");
                32'd24:  check_register(9, 32'd2, "SRL x9");
                32'd28:  check_register(10, 32'hC0000000, "SRA x10");
                32'd32:  check_register(11, 32'd23, "OR x11");
                32'd36:  check_register(12, 32'd0, "AND x12");

                32'd40:  check_memory(5, 32'h00000003, "SW memory[5]");
                32'd44:  check_register(13, 32'h00000003, "LW x13");
                32'd48:  check_memory(5, 32'h00008003, "SB memory[5]");
                32'd52:  check_register(13, 32'hFFFFFF80, "LB x13 sign extension");
                32'd56:  check_register(13, 32'h00000080, "LBU x13 zero extension");
                32'd60:  check_memory(5, 32'h80FF8003, "SH memory[5]");
                32'd64:  check_register(13, 32'hFFFF80FF, "LH x13 sign extension");
                32'd68:  check_register(13, 32'h000080FF, "LHU x13 zero extension");
                32'd72:  check_register(13, 32'h80FF8003, "LW x13 final word");
                32'd76:  check_register(18, 32'h12345000, "LUI x18");
                32'd80:  check_register(19, 32'h00002050, "AUIPC x19");

                32'd84: begin
                    // x20 would be modified by the skipped ADDI at PC 88;
                    // after BEQ, it must still be zero.
                    check_register(20, 32'd0, "BEQ skipped ADDI to x20");
                end
                32'd92:  check_register(21, 32'd36, "ADDI x21 JALR target");
                32'd100: check_register(22, 32'd9, "BNE not taken, ADDI x22");
                32'd112: check_register(24, 32'd11, "BLT target, ADDI x24");
                32'd120: check_register(25, 32'd12, "BGE not taken, ADDI x25");
                32'd128: check_register(26, 32'd13, "BLTU not taken, ADDI x26");
                32'd140: check_register(28, 32'd15, "BGEU target, ADDI x28");

                32'd144: begin
                    check_register(20, 32'd148, "JALR writes PC+4 to x20");
                end

                default: begin
                    // No additional state check is needed at this PC.
                end
            endcase
        end

        // Instructions skipped by taken branches must not have written these regs.
        check_register(23, 32'd0, "BLT skipped ADDI to x23");
        check_register(27, 32'd0, "BGEU skipped ADDI to x27");

        // x0 must always remain zero.
        check_register(0, 32'd0, "x0 remains zero");

        $display("================================================");
        $display("PASS: Top-level RV32I integration test completed.");
        $display("Fetch, Decode, Execute, Memory, Writeback, branches, and JALR passed.");
        $display("================================================");
        $finish;
    end

endmodule
