
module Data_Memory(
    clk,
    reset,
    MemWrite,
    MemRead,
    func3,
    address,
    write_data,
    read_data
);

input clk, reset, MemWrite, MemRead;
input [2:0] func3;
input [31:0] address, write_data;

output reg [31:0] read_data;

reg [31:0] memory [0:255];
reg [31:0] selected_word;

integer i;

// Combinational read and load formatting.
always @(*) begin
    selected_word = memory[address[9:2]];
    read_data = 32'b0;

    if (MemRead) begin
        case (func3)

            // LB: signed byte
            3'b000: begin
                case (address[1:0])
                    2'b00: read_data =
                        {{24{selected_word[7]}}, selected_word[7:0]};
                    2'b01: read_data =
                        {{24{selected_word[15]}}, selected_word[15:8]};
                    2'b10: read_data =
                        {{24{selected_word[23]}}, selected_word[23:16]};
                    2'b11: read_data =
                        {{24{selected_word[31]}}, selected_word[31:24]};
                endcase
            end

            // LH: signed halfword
            3'b001: begin
                if (address[1] == 1'b0)
                    read_data =
                        {{16{selected_word[15]}}, selected_word[15:0]};
                else
                    read_data =
                        {{16{selected_word[31]}}, selected_word[31:16]};
            end

            // LW: full word
            3'b010: read_data = selected_word;

            // LBU: unsigned byte
            3'b100: begin
                case (address[1:0])
                    2'b00: read_data = {24'b0, selected_word[7:0]};
                    2'b01: read_data = {24'b0, selected_word[15:8]};
                    2'b10: read_data = {24'b0, selected_word[23:16]};
                    2'b11: read_data = {24'b0, selected_word[31:24]};
                endcase
            end

            // LHU: unsigned halfword
            3'b101: begin
                if (address[1] == 1'b0)
                    read_data = {16'b0, selected_word[15:0]};
                else
                    read_data = {16'b0, selected_word[31:16]};
            end

            default: read_data = 32'b0;
        endcase
    end
end

// Synchronous reset and word writes.
// Store instructions will be extended separately.
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] <= 32'b0;
    end
    else if (MemWrite) begin
        memory[address[9:2]] <= write_data;
    end
end

endmodule
