`timescale 1ns / 1ps

module core_sim;
    input clk, rst;

    RV32core core(
        .debug_en(1'b0),
        .debug_step(1'b0),
        .debug_addr(7'b0),
        .debug_data(),
        .clk(clk),
        .rst(rst),
        .interrupter(1'b0)
    );

    integer i;

    // signals here
    localparam
        DATA_MEM_SIZE = 128,  // change according to lab6_tomasulo.json
        MAX_FU_NUM = 6,       // change according to lab6_tomasulo.json
        Q_WIDTH = 3,          // change according to lab6_tomasulo.json
        RRS_WIDTH = 3;        // change according to lab6_tomasulo.json
    
    wire [31:0] pc = core.PC_IF;
    reg [31:0] regs [1:31];
    always @* begin
        for(i = 1; i < 32; i = i + 1) begin
            regs[i] <= core.register.register[i];
        end
    end
    reg [MAX_FU_NUM-1:0] busy = ...;
    reg [31:0] vj [0:MAX_FU_NUM-1];
    reg [31:0] vk [0:MAX_FU_NUM-1];
    reg [Q_WIDTH-1:0] qj [0:MAX_FU_NUM-1];
    reg [Q_WIDTH-1:0] qk [0:MAX_FU_NUM-1];
    reg [RRS_WIDTH-1:0] rrs[0:31];
    always @* begin
        // TODO: inplement me!
    end

    reg[7:0] data_mem[0:DATA_MEM_SIZE-1];
    always @* begin
        for (i = 0; i < DATA_MEM_SIZE; i = i + 1) begin
            // TODO: inplement me!
        end
    end

endmodule