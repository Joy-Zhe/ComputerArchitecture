`timescale 1ns / 1ps

module CDBconflict(
    input [3:0] ALU_finish1,
    input [3:0] ALU_finish2,
    input [3:0] ALU_finish3,
    input [3:0] MUL_finish1,
    input [3:0] MUL_finish2,
    input [3:0] DIV_finish1,
    input [3:0] MEM_finish1,
    input [3:0] MEM_finish2,
    input [3:0] JUMP_finish,

    input [4:0] Wt_addr_ALU1, 
    input [31:0]Wt_data_ALU1, 

    input [4:0] Wt_addr_ALU2, 
    input [31:0]Wt_data_ALU2, 

    input [4:0] Wt_addr_ALU3, 
    input [31:0]Wt_data_ALU3, 

    //	JUMP
    input [4:0] Wt_addr_JUMP, 
    input [31:0]Wt_data_JUMP,
    
    //	MEM
    input [4:0] Wt_addr_MEM1, 
    input [31:0]Wt_data_MEM1,
    
    input [4:0] Wt_addr_MEM2, 
    input [31:0]Wt_data_MEM2, 

    //	MUL
    input [4:0] Wt_addr_MUL1, 
    input [31:0]Wt_data_MUL1, 

    input [4:0] Wt_addr_MUL2, 
    input [31:0]Wt_data_MUL2, 

    //	DIV
    input [4:0] Wt_addr_DIV1, 
    input [31:0]Wt_data_DIV1, 
    
    input [4:0] Wt_addr_DIV2, 
    input [31:0]Wt_data_DIV2, 

    output reg [3:0] FU_finish,
    output reg [3:0] Wt_addr_out,
    output reg [31:0] Wt_data_out
);
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

    reg find = 0;

    integer i; // 循环变量

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

endmodule


// `timescale 1ns / 1ps

// module CDBconflict(
//     input [3:0] ALU_finish1,
//     input [3:0] ALU_finish2,
//     input [3:0] ALU_finish3,
//     input [3:0] MUL_finish1,
//     input [3:0] MUL_finish2,
//     input [3:0] DIV_finish1,
//     input [3:0] MEM_finish1,
//     input [3:0] MEM_finish2,
//     input [3:0] JUMP_finish,

//     input [4:0] Wt_addr_ALU1, 
//     input [31:0]Wt_data_ALU1, 

//     input [4:0] Wt_addr_ALU2, 
//     input [31:0]Wt_data_ALU2, 

//     input [4:0] Wt_addr_ALU3, 
//     input [31:0]Wt_data_ALU3, 

//     //	JUMP
//     input [4:0] Wt_addr_JUMP, 
//     input [31:0]Wt_data_JUMP,
    
//     //	MEM
//     input [4:0] Wt_addr_MEM1, 
//     input [31:0]Wt_data_MEM1,
    
//     input [4:0] Wt_addr_MEM2, 
//     input [31:0]Wt_data_MEM2, 

//     //	MUL
//     input [4:0] Wt_addr_MUL1, 
//     input [31:0]Wt_data_MUL1, 

//     input [4:0] Wt_addr_MUL2, 
//     input [31:0]Wt_data_MUL2, 

//     //	DIV
//     input [4:0] Wt_addr_DIV1, 
//     input [31:0]Wt_data_DIV1, 
    
//     input [4:0] Wt_addr_DIV2, 
//     input [31:0]Wt_data_DIV2, 

//     output [3:0] FU_finish
//     output [3:0] Wt_addr
//     output [31:0] Wt_data
// );

//     reg [3:0] queue_finish [0:9] = 0;

//     always @(*) begin
//         if (queue_finish[1] != 4'b0) begin
//             FU_finish = queue_finish[1];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = ALU_finish2;
//             queue_finish[3] = ALU_finish3;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[2] != 4'b0) begin
//             FU_finish = queue_finish[2];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = ALU_finish3;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[3] != 4'b0) begin
//             FU_finish = queue_finish[3];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[4] != 4'b0) begin
//             FU_finish = queue_finish[4];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[5] != 4'b0) begin
//             FU_finish = queue_finish[5];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[6] != 4'b0) begin
//             FU_finish = queue_finish[6];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[7] != 4'b0) begin
//             FU_finish = queue_finish[7];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[8] != 4'b0) begin
//             FU_finish = queue_finish[8];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = 4'b0;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (queue_finish[9] != 4'b0) begin
//             FU_finish = queue_finish[9];
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = 4'b0;
//             queue_finish[9] = 4'b0;
//         end
//         else if (ALU_finish1 != 4'b0) begin
//             FU_finish = ALU_finish1;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = ALU_finish2;
//             queue_finish[3] = ALU_finish3;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (ALU_finish2 != 4'b0) begin
//             FU_finish = ALU_finish2;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = ALU_finish3;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (ALU_finish3 != 4'b0) begin
//             FU_finish = ALU_finish3;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = MUL_finish1;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (MUL_finish1 != 4'b0) begin
//             FU_finish = MUL_finish1;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = MUL_finish2;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (MUL_finish2 != 4'b0) begin
//             FU_finish = MUL_finish2;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = DIV_finish1;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (DIV_finish1 != 4'b0) begin
//             FU_finish = DIV_finish1;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = MEM_finish1;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (MEM_finish1 != 4'b0) begin
//             FU_finish = MEM_finish1;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = MEM_finish2;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (MEM_finish2 != 4'b0) begin
//             FU_finish = MEM_finish2;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = 4'b0;
//             queue_finish[9] = JUMP_finish;
//         end
//         else if (JUMP_finish != 4'b0) begin
//             FU_finish = JUMP_finish;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = 4'b0;
//             queue_finish[9] = 4'b0;
//         end
//         else begin
//             FU_finish = 4'b0;
//             queue_finish[1] = 4'b0;
//             queue_finish[2] = 4'b0;
//             queue_finish[3] = 4'b0;
//             queue_finish[4] = 4'b0;
//             queue_finish[5] = 4'b0;
//             queue_finish[6] = 4'b0;
//             queue_finish[7] = 4'b0;
//             queue_finish[8] = 4'b0;
//             queue_finish[9] = 4'b0;
//         end
//     end

// endmodule