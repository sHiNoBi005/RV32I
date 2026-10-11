module Top(
    input clk,
    input reset,
    output [31:0] PC_out,
    output [31:0] instruction,
    output [31:0] ALU_result,
    output zero
);
    wire [31:0] PC_next;
    wire [31:0] Read_data1, Read_data2, ALU_B;
    wire [31:0] memory_read_data, write_back_data;
    wire branch, jump, jalr;
    wire MemRead, MemtoReg, MemWrite, ALUScr, RegWrite;

    wire br_taken;
    wire branch_taken;

    wire [3:0] ALUControlOut;
    wire [31:0] immediate;
    wire [31:0] PC_plus4;

    
    // Take the branch only when the instruction is a valid
    // branch and the comparison condition is true.
    assign branch_taken = branch && br_taken;

    // Select the next PC.
    assign PC_plus4 = PC_out + 32'd4;

    // JALR target is rs1 + immediate, with bit 0 cleared.
    // Otherwise, retain the existing branch/sequential PC selection.
    assign PC_next = jalr
                ? {ALU_result[31:1], 1'b0}
                : branch_taken
                    ? (PC_out + immediate)
                    : PC_plus4;


    ProgramCounter pc (
        .clk(clk), .reset(reset), .PC_in(PC_next), .PC_out(PC_out)
    );

    InstructionMemory instruction_memory (
        .address(PC_out), .instruction(instruction)
    );

    ControlUnit control_unit (
        .OPcode(instruction[6:0]),
        .func3(instruction[14:12]),
        .func7(instruction[31:25]),
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

    BranchComp branch_comparator (
    .rs1_data(Read_data1),
    .rs2_data(Read_data2),
    .func3(instruction[14:12]),
    .br_taken(br_taken)
    );

    Register_File register_file (
        .clk(clk), .reset(reset),
        .Rs1(instruction[19:15]),
        .Rs2(instruction[24:20]),
        .Rd(instruction[11:7]),
        .Write_data(write_back_data),
        .RegWrite(RegWrite),
        .Read_data1(Read_data1),
        .Read_data2(Read_data2)
    );
    ImmediateGenerator imm_gen (
    .instruction(instruction),
    .immediate(immediate)
    );

    assign ALU_B = ALUScr ? immediate : Read_data2;

    ALU alu (
        .A(Read_data1), .B(ALU_B),
        .ALUControl_in(ALUControlOut),
        .ALU_result(ALU_result), .zero(zero)
    );

    Data_Memory data_memory (
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .func3(instruction[14:12]),
    .address(ALU_result),
    .write_data(Read_data2),
    .read_data(memory_read_data)
    );

    // JALR writes the address of the following instruction to rd.
    assign write_back_data = jalr
                           ? PC_plus4
                           : (MemtoReg ? memory_read_data : ALU_result);
endmodule