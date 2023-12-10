`timescale 1ns / 1ps

module FU_mul(
    input clk, EN,
    input[31:0] A, B,
    output[31:0] res
);

    reg[6:0] state;
    initial begin
        state = 0;
    end

    reg[31:0] A_reg, B_reg;

    //! to fill sth.in
    always @(posedge clk) begin
        if (EN && state == 24'd0) begin
            A_reg <= A;
            B_reg <= B;
            state <= 1;
        end
        else begin
            state <= state << 1;
        end
    end


    wire [63:0] mulres;
    multiplier mul(.CLK(clk),.A(A_reg),.B(B_reg),.P(mulres));

    assign res = mulres[31:0];

endmodule