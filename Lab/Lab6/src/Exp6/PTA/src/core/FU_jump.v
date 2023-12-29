`timescale 1ns / 1ps

module FU_jump(
	input clk, EN, JALR,
	input[3:0] cmp_ctrl,
	input[31:0] rs1_data, rs2_data, imm, PC,
	output[31:0] PC_jump, PC_wb,
	output is_jump, finish, jump
);

	wire cmp_res;
    reg [1:0] state;
    assign finish = (state[0] == 1'b1);// fill sth. here
	initial begin
        state = 0;
    end

	reg JALR_reg;
	reg[3:0] cmp_ctrl_reg = 0;
	reg[31:0] rs1_data_reg = 0, rs2_data_reg = 0, imm_reg = 0, PC_reg = 0;
	reg jump_flag = 0;
	assign jump = (jump_flag == 1'b1);

	// fill sth. here
	always@(posedge clk) begin
		jump_flag <= is_jump;
        if(EN & ~state) begin // state == 0
			JALR_reg <= JALR;
			cmp_ctrl_reg <= cmp_ctrl;
            rs1_data_reg <= rs1_data;
            rs2_data_reg <= rs2_data;
            imm_reg <= imm;
			PC_reg <= PC;
            state <= 2'b10;
        end
        else state <= {1'b0, state[1]};
    end

	cmp_32 cmp(.a(rs1_data_reg),.b(rs2_data_reg),.ctrl(cmp_ctrl_reg[3:1]),.c(cmp_res));

	assign PC_jump = JALR_reg ? rs1_data_reg + imm_reg : PC_reg + imm_reg; // JALR or JAL

	assign PC_wb = PC_reg + 4; // PC + 4

	assign is_jump = (cmp_ctrl_reg[0] | cmp_res) & finish;

endmodule