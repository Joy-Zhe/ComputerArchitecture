`timescale 1ns / 1ps

module FU_mul(
    input clk, EN, EN2,
    input[31:0] A, B,
    input[31:0] A2, B2,
    output[31:0] res,
    output[31:0] res2,
    output finish,
    output finish2
);

    reg[6:0] state;
    reg[6:0] state2;
    assign finish = state[0] == 1'b1;
    assign finish2 = state2[0] == 1'b1;
    initial begin
        state = 0;
        state2 = 0;
    end

    reg[31:0] A_reg, B_reg;

    always@(posedge clk) begin
        if(EN & ~state) begin
            A_reg <= A;
            B_reg <= B;
            state <= 7'b1000000;
        end
        else state <= {1'b0, state[6:1]};

        if(EN2 & ~state2) begin
            A_reg <= A2;
            B_reg <= B2;
            state2 <= 7'b1000000;
        end
        else state2 <= {1'b0, state2[6:1]};
    end

    wire[63:0] mulres;         //to fill sth.in

    multiplier mul(.CLK(clk),.A(A_reg),.B(B_reg),.P(mulres));

    assign res = mulres[31:0];
    assign res2 = mulres[31:0];

endmodule