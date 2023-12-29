`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:34:44 03/12/2012 
// Design Name: 
// Module Name:    Regs 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module Regs(input clk,
			input rst,	
			//	为每一个FU分配对应的读写口
			//	ALU
			input [4:0] R_addr_A_ALU, 
			input [4:0] R_addr_B_ALU, 
			input [4:0] Wt_addr_ALU, 
			input [31:0]Wt_data_ALU, 
			input L_S_ALU, 
			output [31:0] rdata_A_ALU, 
			output [31:0] rdata_B_ALU,

			// ALU2
			input [4:0] R_addr_A_ALU2,
			input [4:0] R_addr_B_ALU2,
			input [4:0] Wt_addr_ALU2,
			input [31:0]Wt_data_ALU2,
			input L_S_ALU2,
			output [31:0] rdata_A_ALU2,
			output [31:0] rdata_B_ALU2,

			//	JUMP
			input [4:0] R_addr_A_JUMP, 
			input [4:0] R_addr_B_JUMP, 
			input [4:0] Wt_addr_JUMP, 
			input [31:0]Wt_data_JUMP, 
			input L_S_JUMP, 
			output [31:0] rdata_A_JUMP, 
			output [31:0] rdata_B_JUMP,
			
			//	MEM
			input [4:0] R_addr_A_MEM, 
			input [4:0] R_addr_B_MEM, 
			input [4:0] Wt_addr_MEM, 
			input [31:0]Wt_data_MEM, 
			input L_S_MEM, 
			output [31:0] rdata_A_MEM, 
			output [31:0] rdata_B_MEM,

			//	MEM2
			input [4:0] R_addr_A_MEM2,
			input [4:0] R_addr_B_MEM2,
			input [4:0] Wt_addr_MEM2,
			input [31:0]Wt_data_MEM2,
			input L_S_MEM2,
			output [31:0] rdata_A_MEM2,
			output [31:0] rdata_B_MEM2,

			//	MUL
			input [4:0] R_addr_A_MUL, 
			input [4:0] R_addr_B_MUL, 
			input [4:0] Wt_addr_MUL, 
			input [31:0]Wt_data_MUL, 
			input L_S_MUL, 
			output [31:0] rdata_A_MUL, 
			output [31:0] rdata_B_MUL,

			//	MUL2
			input [4:0] R_addr_A_MUL2,
			input [4:0] R_addr_B_MUL2,
			input [4:0] Wt_addr_MUL2,
			input [31:0]Wt_data_MUL2,
			input L_S_MUL2,
			output [31:0] rdata_A_MUL2,
			output [31:0] rdata_B_MUL2,

			//	DIV
			input [4:0] R_addr_A_DIV, 
			input [4:0] R_addr_B_DIV, 
			input [4:0] Wt_addr_DIV, 
			input [31:0]Wt_data_DIV, 
			input L_S_DIV, 
			output [31:0] rdata_A_DIV, 
			output [31:0] rdata_B_DIV,

			input [4:0] Debug_addr,         // debug address
			output[31:0] Debug_regs        // debug data
);

	reg [31:0] register [1:31]; 				// r1 - r31
	integer i;


	// fill sth. here
	assign rdata_A_JUMP = (R_addr_A_JUMP == 0) ? 0 : register[R_addr_A_JUMP];// read JUMP
	assign rdata_B_JUMP = (R_addr_B_JUMP == 0) ? 0 : register[R_addr_B_JUMP];   	// read JUMP

	assign rdata_A_ALU = (R_addr_A_ALU == 0) ? 0 : register[R_addr_A_ALU];	// read ALU
	assign rdata_B_ALU = (R_addr_B_ALU == 0) ? 0 : register[R_addr_B_ALU];	// read ALU

	assign rdata_A_ALU2 = (R_addr_A_ALU2 == 0) ? 0 : register[R_addr_A_ALU2];	// read ALU2
	assign rdata_B_ALU2 = (R_addr_B_ALU2 == 0) ? 0 : register[R_addr_B_ALU2];	// read ALU2
	
	assign rdata_A_MEM = (R_addr_A_MEM == 0) ? 0 : register[R_addr_A_MEM];	// read MEM
	assign rdata_B_MEM = (R_addr_B_MEM == 0) ? 0 : register[R_addr_B_MEM];	// read MEM

	assign rdata_A_MEM2 = (R_addr_A_MEM2 == 0) ? 0 : register[R_addr_A_MEM2];	// read MEM2
	assign rdata_B_MEM2 = (R_addr_B_MEM2 == 0) ? 0 : register[R_addr_B_MEM2];	// read MEM2

	assign rdata_A_MUL = (R_addr_A_MUL == 0) ? 0 : register[R_addr_A_MUL];	// read MUL
	assign rdata_B_MUL = (R_addr_B_MUL == 0) ? 0 : register[R_addr_B_MUL];	// read MUL

	assign rdata_A_MUL2 = (R_addr_A_MUL2 == 0) ? 0 : register[R_addr_A_MUL2];	// read MUL2
	assign rdata_B_MUL2 = (R_addr_B_MUL2 == 0) ? 0 : register[R_addr_B_MUL2];	// read MUL2
	
	assign rdata_A_DIV = (R_addr_A_DIV == 0) ? 0 : register[R_addr_A_DIV];	// read DIV
	assign rdata_B_DIV = (R_addr_B_DIV == 0) ? 0 : register[R_addr_B_DIV];	// read DIV

	//	write data
	always @(negedge clk or posedge rst) 
      begin
		if (rst) 	 begin 			// reset
		    for (i=1; i<32; i=i+1)
		    register[i] <= 0;	//i;
		end 
		else begin			
		// fill sth. here	//	write
			if (Wt_addr_ALU != 0 && L_S_ALU == 1) begin
				register[Wt_addr_ALU] <= Wt_data_ALU;
			end
			if (Wt_addr_JUMP != 0 && L_S_JUMP == 1) begin
				register[Wt_addr_JUMP] <= Wt_data_JUMP;
			end
			if (Wt_addr_MEM != 0 && L_S_MEM == 1) begin
				register[Wt_addr_MEM] <= Wt_data_MEM;
			end
			if (Wt_addr_MUL != 0 && L_S_MUL == 1) begin
				register[Wt_addr_MUL] <= Wt_data_MUL;
			end
			if (Wt_addr_DIV != 0 && L_S_DIV == 1) begin
				register[Wt_addr_DIV] <= Wt_data_DIV;
			end
			if (Wt_addr_ALU2 != 0 && L_S_ALU2 == 1) begin
				register[Wt_addr_ALU2] <= Wt_data_ALU2;
			end
			if (Wt_addr_MEM2 != 0 && L_S_MEM2 == 1) begin
				register[Wt_addr_MEM2] <= Wt_data_MEM2;
			end
			if (Wt_addr_MUL2 != 0 && L_S_MUL2 == 1) begin
				register[Wt_addr_MUL2] <= Wt_data_MUL2;
			end
		end
	end
    	
    assign Debug_regs = (Debug_addr == 0) ? 0 : register[Debug_addr];               //TEST

endmodule


