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
        DATA_MEM_SIZE = 128,  // change according to lab6_scoreboard.json
        MAX_FU_NUM = 9,       // change according to lab6_scoreboard.json
        Q_WIDTH = 4,          // change according to lab6_scoreboard.json
        RRS_WIDTH = 4;        // change according to lab6_scoreboard.json
    
    wire [31:0] pc = core.PC_IF;
    reg [31:0] regs [1:31];
    always @* begin
        for(i = 1; i < 32; i = i + 1) begin
            regs[i] <= core.register.register[i];
        end
    end
    reg [MAX_FU_NUM-1:0] busy;
    reg [4:0] fi [0:MAX_FU_NUM-1];
    reg [4:0] fj [0:MAX_FU_NUM-1];
    reg [4:0] fk [0:MAX_FU_NUM-1];
    reg [Q_WIDTH-1:0] qj [0:MAX_FU_NUM-1];
    reg [Q_WIDTH-1:0] qk [0:MAX_FU_NUM-1];
    reg [0:MAX_FU_NUM-1] rj;
    reg [0:MAX_FU_NUM-1] rk;
    reg [RRS_WIDTH-1:0] rrs[0:31];
    always @* begin
        // TODO: inplement me!
        busy[0] = 0;
        fi[0] = 0;
        fj[0] = 0;
        fk[0] = 0;
        qj[0] = 0;
        qk[0] = 0;
        rj[0] = 0;
        rk[0] = 0;
        for(i = 1; i < MAX_FU_NUM; i = i + 1) begin
            busy[i] = core.ctrl.FUS[i][0];
            fi[i] = core.ctrl.FUS[i][10:6];
            fj[i] = core.ctrl.FUS[i][15:11];
            fk[i] = core.ctrl.FUS[i][20:16];
            qj[i] = core.ctrl.FUS[i][24:21];
            qk[i] = core.ctrl.FUS[i][28:25];
            rj[i] = core.ctrl.FUS[i][29];
            rk[i] = core.ctrl.FUS[i][30];
        end
        for (i = 0; i < 32; i = i + 1) begin
            rrs[i] = core.ctrl.RRS[i];
        end
    end

    reg[7:0] data_mem[0:DATA_MEM_SIZE-1];
    always @* begin
        for (i = 0; i < DATA_MEM_SIZE; i = i + 1) begin
            data_mem[i] = core.mem.ram.data[i];
        end
    end

endmodule