`timescale 1ns / 1ps

module FU_mem(
    input clk, EN, mem_w,
    input[2:0] bhw,
    input[31:0] rs1_data, rs2_data, imm,
    output[31:0] mem_data
);

    reg[1:0] state;
    initial begin
        state = 0;
    end

    reg mem_w_reg;
    reg[2:0] bhw_reg;
    reg[31:0] rs1_data_reg, rs2_data_reg, imm_reg;

    //! to fill sth.in
    always @(posedge clk) begin
        if (EN & state == 0) begin
            rs1_data_reg <= rs1_data;
            rs2_data_reg <= rs2_data;
            imm_reg <= imm;
            mem_w_reg <= mem_w;
            bhw_reg <= bhw;
            state <= 1;
        end 
        else begin
            state <= state << 1;
        end
    end

    wire [31:0] mem_addr;
    add_32 add(.a(rs1_data_reg), .b(imm_reg), .res(mem_addr));

    RAM_B ram(.clk(clk),
              .rst(),
              .cs(EN),
              .we(mem_w_reg),
              .addr(mem_addr),
              .din(rs2_data_reg),
              .dout(mem_data),
              .stall(),
              .ack()
              );    //! to fill sth.in

endmodule