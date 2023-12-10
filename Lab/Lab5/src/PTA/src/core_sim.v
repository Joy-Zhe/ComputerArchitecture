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
        DATA_MEM_SIZE = 128,      // change according to lab5.json
        MAX_FU_NUM = 6,           // change according to lab5.json
        MAX_FU_LATENCY = 31;
    
    wire [31:0] pc = core.PC_IF;
    reg [31:0] regs [1:31];
    always @* begin
        for(i = 1; i < 32; i = i + 1) begin
            regs[i] <= core.register.register[i];
        end
    end
    reg [4:0] reservation [0:MAX_FU_LATENCY];
    always @* begin
        for(i = 0; i <= MAX_FU_LATENCY; i = i + 1) begin
            reservation[i] <= core.ctrl.reservation_reg[i];
        end
    end
    wire[MAX_FU_NUM-1:0] fu_status = core.ctrl.FU_status;
    reg [4:0] fu_write_to [0:MAX_FU_NUM-1];
    always @* begin
        for(i = 0; i < MAX_FU_NUM; i = i + 1) begin
            fu_write_to[i] <= core.ctrl.FU_write_to[i];
        end
    end
    wire[MAX_FU_NUM-1:0] fu_writeback_en = core.ctrl.FU_writeback_en;

endmodule