`timescale 1ns/1ps

module ImmediateGenerator_tb;

    reg [31:0] instruction;
    wire [31:0] immediate;

    ImmediateGenerator dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    task check_immediate;
        input [255:0] test_name;
        input [31:0] expected;
        begin
            #1;
            if (immediate !== expected) begin
                $display("FAIL: %0s | instruction=%h | got=%h | expected=%h",
                         test_name, instruction, immediate, expected);
                $fatal(1);
            end
            else begin
                $display("PASS: %0s | immediate=%h", test_name, immediate);
            end
        end
    endtask

    initial begin
        $dumpfile("ImmediateGenerator.vcd");
        $dumpvars(0, ImmediateGenerator_tb);

        // I-type: positive immediate (+12).
        instruction = 32'b0;
        instruction[6:0]   = 7'b0010011; // OP-IMM
        instruction[31:20] = 12'h00C;
        check_immediate("I-type positive", 32'h0000000C);

        // I-type: sign extension of -1.
        instruction = 32'b0;
        instruction[6:0]   = 7'b0000011; // LOAD
        instruction[31:20] = 12'hFFF;
        check_immediate("I-type negative", 32'hFFFFFFFF);

        // S-type: store offset +5.
        instruction = 32'b0;
        instruction[6:0]  = 7'b0100011; // STORE
        instruction[11:7] = 5'b00101;
        check_immediate("S-type positive", 32'h00000005);

        // S-type: store offset -8 (12-bit immediate = 12'hFF8).
        instruction = 32'b0;
        instruction[6:0]   = 7'b0100011;
        instruction[31:25] = 7'b1111111;
        instruction[11:7]  = 5'b11000;
        check_immediate("S-type negative", 32'hFFFFFFF8);

        // B-type: branch offset +12.
        instruction = 32'b0;
        instruction[6:0]  = 7'b1100011; // BRANCH
        instruction[11:8] = 4'b0110;    // immediate[4:1]
        check_immediate("B-type positive", 32'h0000000C);

        // B-type: branch offset -4.
        instruction = 32'b0;
        instruction[6:0]   = 7'b1100011;
        instruction[31]    = 1'b1;      // immediate[12]
        instruction[7]     = 1'b1;      // immediate[11]
        instruction[30:25] = 6'b111111; // immediate[10:5]
        instruction[11:8]  = 4'b1110;   // immediate[4:1]
        check_immediate("B-type negative", 32'hFFFFFFFC);

        // U-type: upper immediate 20'h12345 shifted left by 12.
        instruction = 32'b0;
        instruction[6:0]   = 7'b0110111; // LUI
        instruction[31:12] = 20'h12345;
        check_immediate("U-type LUI", 32'h12345000);

        // J-type: jump offset +8.
        instruction = 32'b0;
        instruction[6:0]    = 7'b1101111; // JAL
        instruction[30:21]  = 10'd4;       // immediate[10:1] = 4
        check_immediate("J-type positive", 32'h00000008);

        // J-type: jump offset -4.
        instruction = 32'b0;
        instruction[6:0]    = 7'b1101111;
        instruction[31]     = 1'b1;       // immediate[20]
        instruction[19:12]  = 8'hFF;      // immediate[19:12]
        instruction[20]     = 1'b1;       // immediate[11]
        instruction[30:21]  = 10'h3FE;   // immediate[10:1]
        check_immediate("J-type negative", 32'hFFFFFFFC);

        // Unsupported opcode: safe default is zero.
        instruction = 32'b0;
        instruction[6:0] = 7'b1111111;
        check_immediate("Unsupported opcode", 32'h00000000);

        $display("PASS: All ImmediateGenerator tests completed.");
        $finish;
    end

endmodule
