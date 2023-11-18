`timescale 1ns / 1ps

module FU_jump(
	input clk, EN, JALR,
	input[2:0] cmp_ctrl,
	input[31:0] rs1_data, rs2_data, imm, PC,
	output[31:0] PC_jump, PC_wb,
	output cmp_res
);

    reg state;
	initial begin
        state = 0;
    end

	reg JALR_reg;
	reg[2:0] cmp_ctrl_reg;
	reg[31:0] rs1_data_reg, rs2_data_reg, imm_reg, PC_reg;
	
	//! to fill sth.in
	always@(posedge clk) begin
		if(EN & ~state) begin
			JALR_reg <= JALR;
			cmp_ctrl_reg <= cmp_ctrl;
			rs1_data_reg <= rs1_data;
			rs2_data_reg <= rs2_data;
			imm_reg <= imm;
			PC_reg <= PC;

			state <= 1;
		end
		else state <= 0;
	end

	assign PC_jump = JALR_reg ? rs1_data_reg + imm_reg : PC_reg + imm_reg; // JALR or JAL
	assign PC_wb = PC_reg + 4; // PC + 4
	cmp_32 cmp(.a(rs1_data_reg), .b(rs2_data_reg), .op(cmp_ctrl_reg), .res(cmp_res));


endmodule