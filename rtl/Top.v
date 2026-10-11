module Top(
    input wire clk,
    input wire reset,

    output wire [31:0] PC_out,
    output wire [31:0] instruction,

    output wire [31:0] ALU_result,
    output wire ALU_zero,

    output wire [31:0] memory_read_data,
    output wire [31:0] writeback_data
);

    // =========================================
    // STAGE 1: FETCH + NEXT-PC SELECTION
    // =========================================

    wire [31:0] pc_plus4;
    wire [31:0] PC_next;
    wire [31:0] branch_target;
    wire [31:0] jalr_target;

    assign pc_plus4     = PC_out + 32'd4;
    assign branch_target = PC_out + immediate;
    assign jalr_target   = {ALU_result[31:1], 1'b0};

    ProgramCounter pc (
        .clk(clk),
        .reset(reset),
        .PC_in(PC_next),
        .PC_out(PC_out)
    );

    InstructionMemory instruction_memory (
        .address(PC_out),
        .instruction(instruction)
    );


    // =========================================
    // STAGE 2: DECODE
    // =========================================

    wire [6:0] opcode;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] func3;
    wire [6:0] func7;

    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign func3  = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign func7  = instruction[31:25];

    wire [31:0] Read_data1;
    wire [31:0] Read_data2;
    wire [31:0] immediate;

    ImmediateGenerator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    wire branch;
    wire jump;
    wire jalr;
    wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire ALUScr;
    wire RegWrite;
    wire [3:0] ALUControlOut;

    ControlUnit control_unit (
        .OPcode(opcode),
        .func3(func3),
        .func7(func7),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUScr(ALUScr),
        .RegWrite(RegWrite),
        .ALUControlOut(ALUControlOut)
    );


    // =========================================
    // STAGE 3: EXECUTE
    // =========================================

    wire [31:0] ALU_A;
    wire [31:0] ALU_B;

    // LUI:   zero + immediate
    // AUIPC: current PC + immediate
    // Others: register rs1 + selected operand B
    assign ALU_A =
        (opcode == 7'b0110111) ? 32'b0 :
        (opcode == 7'b0010111) ? PC_out :
                                 Read_data1;

    assign ALU_B = ALUScr ? immediate : Read_data2;

    ALU alu (
        .A(ALU_A),
        .B(ALU_B),
        .ALUControl_in(ALUControlOut),
        .ALU_result(ALU_result),
        .zero(ALU_zero)
    );


    // =========================================
    // BRANCH COMPARISON
    // =========================================

    wire branch_taken;

    BranchComp branch_comparator (
        .rs1_data(Read_data1),
        .rs2_data(Read_data2),
        .func3(func3),
        .br_taken(branch_taken)
    );


    // =========================================
    // NEXT-PC CONTROL
    // =========================================

    // Priority:
    // 1. JALR:       rs1 + immediate, with bit 0 cleared
    // 2. JAL:        PC + J-type immediate
    // 3. Taken branch: PC + B-type immediate
    // 4. Otherwise:  PC + 4

    assign PC_next =
        jalr ? jalr_target :
        jump ? branch_target :
        (branch && branch_taken) ? branch_target :
        pc_plus4;


    // =========================================
    // STAGE 4: MEMORY
    // =========================================

    Data_Memory data_memory (
        .clk(clk),
        .reset(reset),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .func3(func3),
        .address(ALU_result),
        .write_data(Read_data2),
        .read_data(memory_read_data)
    );


    // =========================================
    // STAGE 5: REGISTER WRITEBACK
    // =========================================

    // JAL/JALR write PC+4.
    // Loads write memory data.
    // Other register-writing instructions write the ALU result.

    assign writeback_data =
        (jump || jalr) ? pc_plus4 : MemtoReg ? memory_read_data : ALU_result;

    Register_File register_file (
        .clk(clk),
        .reset(reset),
        .Rs1(rs1),
        .Rs2(rs2),
        .Rd(rd),
        .Write_data(writeback_data),
        .RegWrite(RegWrite),
        .Read_data1(Read_data1),
        .Read_data2(Read_data2)
    );

endmodule