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
			// for CtrlUnit
			input [4:0] rs1_addr,
			input [4:0] rs2_addr,
			output [31:0] rs1_val,
			output [31:0] rs2_val,
			//	为每�??个FU分配对应的读写口
			//	ALU
			// input [4:0] R_addr_A_ALU1, 
			// input [4:0] R_addr_B_ALU1, 
			input [4:0] Wt_addr_ALU1, 
			input [31:0]Wt_data_ALU1, 
			input [3:0]ALU_finish1, 
			// output [31:0] rdata_A_ALU1, 
			// output [31:0] rdata_B_ALU1,

			// input [4:0] R_addr_A_ALU2, 
			// input [4:0] R_addr_B_ALU2, 
			input [4:0] Wt_addr_ALU2, 
			input [31:0]Wt_data_ALU2, 
			input [3:0]ALU_finish2, 
			// output [31:0] rdata_A_ALU2, 
			// output [31:0] rdata_B_ALU2,

			// input [4:0] R_addr_A_ALU3, 
			// input [4:0] R_addr_B_ALU3, 
			input [4:0] Wt_addr_ALU3, 
			input [31:0]Wt_data_ALU3, 
			input [3:0]ALU_finish3, 
			// output [31:0] rdata_A_ALU3, 
			// output [31:0] rdata_B_ALU3,

			//	JUMP
			// input [4:0] R_addr_A_JUMP, 
			// input [4:0] R_addr_B_JUMP, 
			input [4:0] Wt_addr_JUMP, 
			input [31:0]Wt_data_JUMP, 
			input [3:0]JUMP_finish, 
			// output [31:0] rdata_A_JUMP, 
			// output [31:0] rdata_B_JUMP,
			
			//	MEM
			// input [4:0] R_addr_A_MEM1, 
			// input [4:0] R_addr_B_MEM1, 
			input [4:0] Wt_addr_MEM1, 
			input [31:0]Wt_data_MEM1, 
			input [3:0]MEM_finish1, 
			// output [31:0] rdata_A_MEM1, 
			// output [31:0] rdata_B_MEM1,

			// input [4:0] R_addr_A_MEM2, 
			// input [4:0] R_addr_B_MEM2, 
			input [4:0] Wt_addr_MEM2, 
			input [31:0]Wt_data_MEM2, 
			input [3:0]MEM_finish2, 
			// output [31:0] rdata_A_MEM2, 
			// output [31:0] rdata_B_MEM2,

			//	MUL
			// input [4:0] R_addr_A_MUL1, 
			// input [4:0] R_addr_B_MUL1, 
			input [4:0] Wt_addr_MUL1, 
			input [31:0]Wt_data_MUL1, 
			input [3:0]MUL_finish1, 
			// output [31:0] rdata_A_MUL1, 
			// output [31:0] rdata_B_MUL1,

			// input [4:0] R_addr_A_MUL2, 
			// input [4:0] R_addr_B_MUL2, 
			input [4:0] Wt_addr_MUL2, 
			input [31:0]Wt_data_MUL2, 
			input [3:0]MUL_finish2, 
			// output [31:0] rdata_A_MUL2, 
			// output [31:0] rdata_B_MUL2,

			//	DIV
			// input [4:0] R_addr_A_DIV1, 
			// input [4:0] R_addr_B_DIV1, 
			input [4:0] Wt_addr_DIV1, 
			input [31:0]Wt_data_DIV1, 
			input [3:0]DIV_finish1, 
			// output [31:0] rdata_A_DIV1, 
			// output [31:0] rdata_B_DIV1,

			// input [4:0] R_addr_A_DIV2, 
			// input [4:0] R_addr_B_DIV2, 
		/* 	input [4:0] Wt_addr_DIV2, 
			input [31:0]Wt_data_DIV2, 
			input [3:0]L_S_DIV2,  */
			// output [31:0] rdata_A_DIV2, 
			// output [31:0] rdata_B_DIV2,

			input [4:0] Debug_addr,         // debug address
			output[31:0] Debug_regs        // debug data
);

	reg [31:0] register [1:31]; 				// r1 - r31
	integer i;


	// fill sth. here
	// assign rdata_A_JUMP = (R_addr_A_JUMP == 0) ? 0 : register[R_addr_A_JUMP];		// read JUMP
	// assign rdata_B_JUMP = (R_addr_B_JUMP == 0) ? 0 : register[R_addr_B_JUMP];   	// read JUMP

	// assign rdata_A_ALU1 = (R_addr_A_ALU1 == 0) ? 0 : register[R_addr_A_ALU1];		// read ALU
	// assign rdata_B_ALU1 = (R_addr_B_ALU1 == 0) ? 0 : register[R_addr_B_ALU1];	    // read ALU

	// assign rdata_A_ALU2 = (R_addr_A_ALU2 == 0) ? 0 : register[R_addr_A_ALU2];		// read ALU
	// assign rdata_B_ALU2 = (R_addr_B_ALU2 == 0) ? 0 : register[R_addr_B_ALU2];	    // read ALU

	// assign rdata_A_ALU3 = (R_addr_A_ALU3 == 0) ? 0 : register[R_addr_A_ALU3];		// read ALU
	// assign rdata_B_ALU3 = (R_addr_B_ALU3 == 0) ? 0 : register[R_addr_B_ALU3];	    // read ALU
	
	// assign rdata_A_MEM1 = (R_addr_A_MEM1 == 0) ? 0 : register[R_addr_A_MEM1];		// read MEM
	// assign rdata_B_MEM1 = (R_addr_B_MEM1 == 0) ? 0 : register[R_addr_B_MEM1];	  	// read MEM	

	// assign rdata_A_MEM2 = (R_addr_A_MEM2 == 0) ? 0 : register[R_addr_A_MEM2];		// read MEM
	// assign rdata_B_MEM2 = (R_addr_B_MEM2 == 0) ? 0 : register[R_addr_B_MEM2];	  	// read MEM	

	// assign rdata_A_MUL1 = (R_addr_A_MUL1 == 0) ? 0 : register[R_addr_A_MUL1];		// read MUL
	// assign rdata_B_MUL1 = (R_addr_B_MUL1 == 0) ? 0 : register[R_addr_B_MUL1];		// read MUL

	// assign rdata_A_MUL2 = (R_addr_A_MUL2 == 0) ? 0 : register[R_addr_A_MUL2];		// read MUL
	// assign rdata_B_MUL2 = (R_addr_B_MUL2 == 0) ? 0 : register[R_addr_B_MUL2];		// read MUL
	
	// assign rdata_A_DIV1 = (R_addr_A_DIV1 == 0) ? 0 : register[R_addr_A_DIV1];		// read DIV
	// assign rdata_B_DIV1 = (R_addr_B_DIV1 == 0) ? 0 : register[R_addr_B_DIV1];	  	// read DIV	

	// assign rdata_A_DIV2 = (R_addr_A_DIV2 == 0) ? 0 : register[R_addr_A_DIV2];		// read DIV
	// assign rdata_B_DIV2 = (R_addr_B_DIV2 == 0) ? 0 : register[R_addr_B_DIV2];	  	// read DIV	

	assign rs1_val = (rs1_addr == 0) ? 0 : register[rs1_addr];		// read rs1
	assign rs2_val = (rs2_addr == 0) ? 0 : register[rs2_addr];		// read rs2
   
wire [3:0] finish_signals [1:9];
    wire [4:0] Wt_addr [1:9];
    wire [31:0] Wt_data [1:9];
    assign finish_signals[1] = ALU_finish1;
    assign finish_signals[2] = ALU_finish2;
    assign finish_signals[3] = ALU_finish3;
    assign finish_signals[4] = MUL_finish1;
    assign finish_signals[5] = MUL_finish2;
    assign finish_signals[6] = DIV_finish1;
    assign finish_signals[7] = MEM_finish1;
    assign finish_signals[8] = MEM_finish2;
    assign finish_signals[9] = JUMP_finish;
    assign Wt_addr[1] = Wt_addr_ALU1;
    assign Wt_addr[2] = Wt_addr_ALU2;
    assign Wt_addr[3] = Wt_addr_ALU3;
    assign Wt_addr[4] = Wt_addr_MUL1;
    assign Wt_addr[5] = Wt_addr_MUL2;
    assign Wt_addr[6] = Wt_addr_DIV1;
    assign Wt_addr[7] = Wt_addr_MEM1;
    assign Wt_addr[8] = Wt_addr_MEM2;
    assign Wt_addr[9] = Wt_addr_JUMP;
    assign Wt_data[1] = Wt_data_ALU1;
    assign Wt_data[2] = Wt_data_ALU2;
    assign Wt_data[3] = Wt_data_ALU3;
    assign Wt_data[4] = Wt_data_MUL1;
    assign Wt_data[5] = Wt_data_MUL2;
    assign Wt_data[6] = Wt_data_DIV1;
    assign Wt_data[7] = Wt_data_MEM1;
    assign Wt_data[8] = Wt_data_MEM2;
    assign Wt_data[9] = Wt_data_JUMP;

    reg [3:0] queue_finish [1:9];
    reg [4:0] queue_wt_addr [1:9]; 
    reg [31:0] queue_wt_data [1:9];
    
    reg [3:0] FU_finish;
    reg [3:0] Wt_addr_out;
    reg [31:0] Wt_data_out;
    
    reg find = 0;

	 always @(*) begin
        for (i = 1; i <= 9; i = i + 1) begin
            if (find == 1'b1 && finish_signals[i] != 4'b0) begin
                queue_finish[i] = finish_signals[i];
                queue_wt_addr[i] = Wt_addr[i];
                queue_wt_data[i] = Wt_data[i];
            end else if (finish_signals[i] == 4'b0) begin
                queue_finish[i] = 4'b0;
                queue_wt_addr[i] = 5'b0;
                queue_wt_data[i] = 32'b0;                
            end
            
            if (queue_finish[i] != 4'b0 && find == 0) begin
                FU_finish = queue_finish[i];
                Wt_addr_out = queue_wt_addr[i];
                Wt_data_out = queue_wt_data[i];
                queue_finish[i] = 4'b0;
                queue_wt_addr[i] = 5'b0;
                queue_wt_data[i] = 32'b0;
                find = 1'b1;
            end
            else if (finish_signals[i] != 4'b0 && find == 0) begin
                FU_finish = finish_signals[i];
                Wt_addr_out = Wt_addr[i];
                Wt_data_out = Wt_data[i];
                find = 1'b1;
            end
        end
        if (find == 0) begin
            FU_finish = 4'b0;
            Wt_addr_out = 4'b0;
            Wt_data_out = 32'b0;
        end else begin
            find = 0;
        end
    end
	//	write data
	always @(negedge clk or posedge rst) 
      begin
		// fill sth. here	//	write
		if (rst) 	 begin 			// reset
		    for (i=1; i<32; i=i+1)
		    register[i] <= 0;	//i;
		end else if(FU_finish != 0) begin
			 if(Wt_addr_out!=0)	register[Wt_addr_out] <= Wt_data_out;
			end
			/* if (Wt_addr_ALU1 != 0 && L_S_ALU1 == 1) register[Wt_addr_ALU1] <= Wt_data_ALU1;		// write ALU
			if (Wt_addr_ALU2 != 0 && L_S_ALU2 == 1) register[Wt_addr_ALU2] <= Wt_data_ALU2;		// write ALU
			if (Wt_addr_ALU3 != 0 && L_S_ALU3 == 1) register[Wt_addr_ALU3] <= Wt_data_ALU3;		// write ALU
			if (Wt_addr_JUMP != 0 && L_S_JUMP == 1) register[Wt_addr_JUMP] <= Wt_data_JUMP;	// write JUMP
			if (Wt_data_MEM1 != 0 && L_S_MEM1 == 1) register[Wt_addr_MEM1] <= Wt_data_MEM1;		// write MEM
			if (Wt_data_MEM2 != 0 && L_S_MEM2 == 1) register[Wt_addr_MEM2] <= Wt_data_MEM2;		// write MEM
			if (Wt_addr_MUL1 != 0 && L_S_MUL1 == 1) register[Wt_addr_MUL1] <= Wt_data_MUL1;		// write MUL
			if (Wt_addr_MUL2 != 0 && L_S_MUL2 == 1) register[Wt_addr_MUL2] <= Wt_data_MUL2;		// write MUL
			if (Wt_addr_DIV1 != 0 && L_S_DIV1 == 1) register[Wt_addr_DIV1] <= Wt_data_DIV1;		// write DIV
			if (Wt_addr_DIV2 != 0 && L_S_DIV2 == 1) register[Wt_addr_DIV2] <= Wt_data_DIV2; */		// write DIV
		end
    	
    assign Debug_regs = (Debug_addr == 0) ? 0 : register[Debug_addr];               //TEST

endmodule


