`timescale 1ns / 1ps

module FU_jump(
	input clk, EN, JALR,
	input[3:0] FU_ID,
	input[3:0] cmp_ctrl,
	input[31:0] rs1_data, rs2_data, imm, PC,
	output[31:0] PC_jump, PC_wb,
	output is_jump,
	output[3:0] finish
);

	wire cmp_res;
    reg state;
    assign finish = state == 1 ? FU_ID : 0;// fill sth. here
	initial begin
        state = 0;
    end

	reg JALR_reg;
	reg[3:0] cmp_ctrl_reg = 0;
	reg[31:0] rs1_data_reg = 0, rs2_data_reg = 0, imm_reg = 0, PC_reg = 0;

	always@(posedge clk) begin
        if(EN & ~state) begin // state == 0
            JALR_reg <= JALR;
            cmp_ctrl_reg <= cmp_ctrl;
            rs1_data_reg <= rs1_data;
            rs2_data_reg <= rs2_data;
            imm_reg <= imm;
            PC_reg <= PC;             //! to fill sth.in
            state <= 1;
        end
        else state <= 0;
    end
    
    cmp_32 cmp_32(.a(rs1_data_reg),.b(rs2_data_reg),.ctrl(cmp_ctrl_reg),.c(cmp_res));
    
    assign PC_jump = JALR_reg ? rs1_data_reg + imm_reg : PC_reg + imm_reg; // JALR or JAL
    assign PC_wb = PC + 32'd4;

	assign is_jump = cmp_res | JALR;// fill sth. here

endmodule