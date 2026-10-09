module InstructionMemory(
    address,
    reset,
    instruction
);
    //making memory

    reg[31:0] memory[0:255] ; //instruction memory with 256 registers ,each 32 bits wide

    input [31:0] address;
    input reset;
    output [31:0] instruction;

    assign instruction=memory[address[9:2]];
    integer k;
    always @(posedge reset)
    begin
        for(k=0;k<256;k=k+1)
        begin
            memory[k]=32'h00000000;
        end
    end

endmodule