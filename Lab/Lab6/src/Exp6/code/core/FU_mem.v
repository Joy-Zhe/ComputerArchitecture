`timescale 1ns / 1ps

module FU_mem(
    input clk, EN, EN2, mem_w, mem_w2,
    input[2:0] bhw,
    input[2:0] bhw2,
    input[31:0] rs1_data, rs2_data, imm,
    input[31:0] rs1_data2, rs2_data2, imm2,
    output[31:0] mem_data, mem2_data,
    output finish, finish2
);

    reg [1:0] state;
    reg [1:0] state2;
    assign finish = state[0] == 1'b1;
    assign finish2 = state2[0] == 1'b1;
    initial begin
        state = 0;
    end

    reg mem_w_reg;
    reg mem_w_reg2;
    reg[2:0] bhw_reg;
    reg[2:0] bhw_reg2;
    reg[31:0] rs1_data_reg, rs2_data_reg, imm_reg;
    reg[31:0] rs1_data_reg2, rs2_data_reg2, imm_reg2;
    wire [31:0] mem_data_out, rs1_data_ram, rs2_data_ram, imm_ram;
    wire [2:0] bhw_ram;
    wire wea_out;

    assign wea_out = (mem_w_reg & finish) | (mem_w_reg2 & finish2) ? 1'b1 : 1'b0;
    assign mem_data = (finish) ? mem_data_out : 32'b0;
    assign mem2_data = (finish2) ? mem_data_out : 32'b0;

    always@(posedge clk) begin
        if(EN & ~state) begin
            mem_w_reg <= mem_w;
            bhw_reg <= bhw;
            rs1_data_reg <= rs1_data;
            rs2_data_reg <= rs2_data;
            imm_reg <= imm;
            state <= 2'b10;
        end
        else begin
            state <= {1'b0, state[1]};
        end

        if(EN2 & ~state2) begin
            mem_w_reg2 <= mem_w2;
            bhw_reg2 <= bhw2;
            rs1_data_reg2 <= rs1_data2;
            rs2_data_reg2 <= rs2_data2;
            imm_reg2 <= imm2;
            state2 <= 2'b10;
        end
        else begin
            state2 <= {1'b0, state2[1]};
        end
    end

    assign rs1_data_ram = (~finish2) ? rs1_data_reg : ((~finish) ? rs1_data_reg2 : 32'b0);
    assign rs2_data_ram = (~finish2) ? rs2_data_reg : ((~finish) ? rs2_data_reg2 : 32'b0);
    assign imm_ram = (~finish2) ? imm_reg : ((~finish) ? imm_reg2 : 32'b0);
    assign bhw_ram = (~finish2) ? bhw_reg : ((~finish) ? bhw_reg2 : 3'b0);

    wire[31:0] addr;

    add_32 add(.a(rs1_data_ram),.b(imm_ram),.c(addr));         //to fill sth.in

    RAM_B ram(.clka(clk),.addra(addr),.dina(rs2_data_ram),.wea(wea_out),
        .douta(mem_data_out),.mem_u_b_h_w(bhw_ram));

endmodule