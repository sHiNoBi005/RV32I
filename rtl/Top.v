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
    wire branch, MemRead, MemtoReg, MemWrite, ALUScr, RegWrite;
    wire [3:0] ALUControlOut;

    assign PC_next = PC_out + 32'd4;

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
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUScr(ALUScr),
        .RegWrite(RegWrite),
        .ALUControlOut(ALUControlOut)
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

    assign ALU_B = ALUScr ? {{20{instruction[31]}}, instruction[31:20]}
                         : Read_data2;

    ALU alu (
        .A(Read_data1), .B(ALU_B),
        .ALUControl_in(ALUControlOut),
        .ALU_result(ALU_result), .zero(zero)
    );

    Data_Memory data_memory (
        .clk(clk), .reset(reset),
        .MemWrite(MemWrite), .MemRead(MemRead),
        .address(ALU_result), .write_data(Read_data2),
        .read_data(memory_read_data)
    );

    assign write_back_data = MemtoReg ? memory_read_data : ALU_result;
endmodule
