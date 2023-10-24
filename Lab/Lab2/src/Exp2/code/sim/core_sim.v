`timescale 1ns / 1ps

module core_sim;
    reg clk, rst;
    reg test_int;

    RV32core core(
        .debug_en(1'b0),
        .debug_step(1'b0),
        .debug_addr(7'b0),
        .debug_data(),
        .clk(clk),
        .rst(rst),
        // .interrupter(1'b0)
        .interrupter(test_int)
    );

    initial begin
        clk = 0;
        rst = 1;
        test_int = 0;
        #2 rst = 0;
        // #10 test_int = 1;
        #186 test_int = 1;
        #1 test_int = 0;
    end
    always #1 clk = ~clk;

endmodule