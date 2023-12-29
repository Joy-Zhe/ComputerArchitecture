`timescale 1ns / 1ps

module FU_mul(
    input clk, EN,
    input[3:0] FU_ID,
    input[31:0] A, B,
    output[31:0] res,
    output[3:0] finish
);

    reg[6:0] state = 0;
    assign finish = state[0] == 1'b1 ? FU_ID : 0;
    initial begin
        state = 0;
    end

    reg[31:0] A_reg, B_reg;

    always@(posedge clk) begin
        if(EN & ~state) begin // state == 0
            A_reg <= A;
            B_reg <= B;             //! to fill sth.in
            state <= 1;
        end
        else state <= 0;
    end

    wire [63:0] mulres;
    multiplier mul(.CLK(clk),.A(A_reg),.B(B_reg),.P(mulres));

    assign res = mulres[31:0];

endmodule