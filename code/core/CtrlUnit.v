
`timescale 1ns / 1ps
`include "CtrlDefine.vh"

module CtrlUnit(
    input clk,
    input rst,

    input[31:0] PC_IF,
    input[31:0] inst_IF,

    input[31:0] PC,
    input[31:0] inst,
    input[31:0] imm,
    input[31:0] rs1_val,
    input[31:0] rs2_val,

    input [3:0]ALU_done,
    input [3:0]MEM_done,
    input [3:0]MUL_done,
    input [3:0]DIV_done,
    input [3:0]JUMP_done,
    input [31:0]ALU_done_val,
    input [31:0]MEM_done_val,
    input [31:0]MUL_done_val,
    input [31:0]DIV_done_val,
    input [31:0]JUMP_done_val,
    input is_jump,

    // IF
    output IS_en,

    // IS
    output[2:0] ImmSel,

    // RO/FU
    output reg ALU_en1, ALU_en2, ALU_en3, MEM_en1, MEM_en2, MUL_en, DIV_en, JUMP_en,
        
            //  ALU
            output reg[31:0] PC_ctrl_ALU1,
            output reg[31:0] imm_ctrl_ALU1,
            output reg[31:0] rs1_ctrl_ALU1, rs2_ctrl_ALU1, 
            output reg[31:0] PC_ctrl_ALU2,
            output reg[31:0] imm_ctrl_ALU2,
            output reg[31:0] rs1_ctrl_ALU2, rs2_ctrl_ALU2, 
            output reg[31:0] PC_ctrl_ALU3,
            output reg[31:0] imm_ctrl_ALU3,
            output reg[31:0] rs1_ctrl_ALU3, rs2_ctrl_ALU3, 

            //  JUMP
            output reg[31:0] PC_ctrl_JUMP,
            output reg[31:0] imm_ctrl_JUMP,
            output reg[31:0] rs1_ctrl_JUMP, rs2_ctrl_JUMP, 

            //  MEM
            output reg[31:0] imm_ctrl_MEM1,
            output reg[31:0] rs1_ctrl_MEM1, rs2_ctrl_MEM1, 
            output reg[31:0] imm_ctrl_MEM2,
            output reg[31:0] rs1_ctrl_MEM2, rs2_ctrl_MEM2,

            //  MUL
            output reg[31:0] rs1_ctrl_MUL, rs2_ctrl_MUL, 

            //  DIV
            output reg[31:0] rs1_ctrl_DIV, rs2_ctrl_DIV, 
    
    // FU
    output reg[4:0] JUMP_op,
    output reg[3:0] ALU_op1,
    output reg ALU_use_PC1,
    output reg ALU_use_imm1,
    output reg[3:0] ALU_op2,
    output reg ALU_use_PC2,
    output reg ALU_use_imm2,
    output reg[3:0] ALU_op3,
    output reg ALU_use_PC3,
    output reg ALU_use_imm3,
    output reg MEM_we1,
    output reg[2:0] MEM_bhw1,
    output reg MEM_we2,
    output reg[2:0] MEM_bhw2,
    output reg[2:0] MUL_op,
    output reg[1:0] DIV_op,
    
    // WB
            //  ALU
            output reg reg_write_ALU1,
            output reg[4:0] rd_ctrl_ALU1,
            output reg reg_write_ALU2,
            output reg[4:0] rd_ctrl_ALU2,
            output reg reg_write_ALU3,
            output reg[4:0] rd_ctrl_ALU3,

            //  JUMP
            output reg reg_write_JUMP,
            output reg[4:0] rd_ctrl_JUMP,
            
            //  MEM
            output reg reg_write_MEM1,
            output reg[4:0] rd_ctrl_MEM1,
            output reg reg_write_MEM2,
            output reg[4:0] rd_ctrl_MEM2,

            //  MUL
            output reg reg_write_MUL,
            output reg[4:0] rd_ctrl_MUL,
            
            //  DIV
            output reg reg_write_DIV,
            output reg[4:0] rd_ctrl_DIV,
    // Debug
    input[4:0] debug_addr,
    output[31:0] Testout
);
    // used in for loop
    integer i;


// RS表�?�从RS[1]�?始依次为1:add1,2:add2,3:add3,4:mul1,5:mul2,6:div1,7:mem1,8:mem2 9:branch1                   
// |  0 |1  5|6 37|38 69|70 74|75 79|80 111|112 143|144 148|
// |Busy| OP | Vj | Vk  | Qj  | Qk  | imm  | PC    | rd    |
    reg[148:0] RS[1:12];  

//RRS:Register result status
    reg[4:0] RRS[0:31];

  /*   reg[31:0] FUS[1:5];
    reg[31:0] IMM[1:5];

    // records which FU will write corresponding reg at WB
    reg[2:0] RRS[0:31]; 

    // sometimes an instruction needs PC to execute
    // pc record
    reg[31:0] PCR[1:5];
    reg[31:0] Inst[1:5]; */

    wire RO_en;
    wire normal_stall;
    reg ctrl_stall = 0, IS_flush = 0;



    // instruction field
    wire[6:0] funct7 = inst[31:25];
    wire[2:0] funct3 = inst[14:12];
    wire[6:0] opcode = inst[6:0];
    wire[4:0] rd = inst[11:7];
    wire[4:0] rs1 = inst[19:15];
    wire[4:0] rs2 = inst[24:20];

    // type specification
    wire Rop = opcode == 7'b0110011;
    wire Iop = opcode == 7'b0010011;
    wire Bop = opcode == 7'b1100011;
    wire Lop = opcode == 7'b0000011;
    wire Sop = opcode == 7'b0100011;

    wire funct7_0  = funct7 == 7'h0;
    wire funct7_1  = funct7 == 7'h1;
    wire funct7_32 = funct7 == 7'h20;

    wire funct3_0 = funct3 == 3'h0;
    wire funct3_1 = funct3 == 3'h1;
    wire funct3_2 = funct3 == 3'h2;
    wire funct3_3 = funct3 == 3'h3;
    wire funct3_4 = funct3 == 3'h4;
    wire funct3_5 = funct3 == 3'h5;
    wire funct3_6 = funct3 == 3'h6;
    wire funct3_7 = funct3 == 3'h7;

    wire ADD  = Rop & funct3_0 & funct7_0;
    wire SUB  = Rop & funct3_0 & funct7_32;
    wire SLL  = Rop & funct3_1 & funct7_0;
    wire SLT  = Rop & funct3_2 & funct7_0;
    wire SLTU = Rop & funct3_3 & funct7_0;
    wire XOR  = Rop & funct3_4 & funct7_0;
    wire SRL  = Rop & funct3_5 & funct7_0;
    wire SRA  = Rop & funct3_5 & funct7_32;
    wire OR   = Rop & funct3_6 & funct7_0;
    wire AND  = Rop & funct3_7 & funct7_0;

    wire MUL    = Rop & funct3_0 & funct7_1;
    wire MULH   = Rop & funct3_1 & funct7_1;
    wire MULHSU = Rop & funct3_2 & funct7_1;
    wire MULHU  = Rop & funct3_3 & funct7_1;
    wire DIV    = Rop & funct3_4 & funct7_1;
    wire DIVU   = Rop & funct3_5 & funct7_1;
    wire REM    = Rop & funct3_6 & funct7_1;
    wire REMU    = Rop & funct3_7 & funct7_1;

    wire ADDI  = Iop & funct3_0;	
    wire SLTI  = Iop & funct3_2;
    wire SLTIU = Iop & funct3_3;
    wire XORI  = Iop & funct3_4;
    wire ORI   = Iop & funct3_6;
    wire ANDI  = Iop & funct3_7;
    wire SLLI  = Iop & funct3_1 & funct7_0;
    wire SRLI  = Iop & funct3_5 & funct7_0;
    wire SRAI  = Iop & funct3_5 & funct7_32;

    wire BEQ = Bop & funct3_0;
    wire BNE = Bop & funct3_1;
    wire BLT = Bop & funct3_4;
    wire BGE = Bop & funct3_5;
    wire BLTU = Bop & funct3_6;
    wire BGEU = Bop & funct3_7;

    wire LB =  Lop & funct3_0;
    wire LH =  Lop & funct3_1;
    wire LW =  Lop & funct3_2;
    wire LBU = Lop & funct3_4;
    wire LHU = Lop & funct3_5;

    wire SB = Sop & funct3_0;
    wire SH = Sop & funct3_1;
    wire SW = Sop & funct3_2;

    wire LUI   = opcode == 7'b0110111;
    wire AUIPC = opcode == 7'b0010111;

    wire JAL  =  opcode == 7'b1101111;
    wire JALR = (opcode == 7'b1100111) && funct3_0;

    wire R_valid = AND | OR | ADD | XOR | SLL | SRL | SRA | SUB | SLT | SLTU 
        | MUL | MULH | MULHSU | MULHU | DIV | DIVU | REM | REMU;
    wire I_valid = ANDI | ORI | ADDI | XORI | SLLI | SRLI | SRAI | SLTI | SLTIU;
    wire B_valid = BEQ | BNE | BLT | BGE | BLTU | BGEU;
    wire L_valid = LW | LH | LB | LHU | LBU;
    wire S_valid = SW | SH | SB;

    // function unit specification
    wire use_ALU = AND | OR | ADD | XOR | SLL | SRL | SRA | SUB | SLT | SLTU
        | I_valid | LUI | AUIPC;
    wire use_MEM = L_valid | S_valid;
    wire use_MUL = MUL | MULH | MULHSU | MULHU;
    wire use_DIV = DIV | DIVU | REM | REMU;
    wire use_JUMP = B_valid | JAL | JALR;

    wire[2:0] use_FU = {3{use_ALU}}  & 3'd1 |
                        {3{use_MEM}}  & 3'd2 |
                        {3{use_MUL}}  & 3'd3 |
                        {3{use_DIV}}  & 3'd4 |
                        {3{use_JUMP}} & 3'd5 ;         // fill sth. here     

    wire[4:0] op = {5{ADD}}          & `ALU_ADD    |
                   {5{SUB}}          & `ALU_SUB    |
                   {5{AND}}          & `ALU_AND    |
                   {5{OR}}           & `ALU_OR     |
                   {5{XOR}}          & `ALU_XOR    |
                   {5{SLL}}          & `ALU_SLL    |
                   {5{SRL}}          & `ALU_SRL    |
                   {5{SLT}}          & `ALU_SLT    |
                   {5{SLTU}}         & `ALU_SLTU   |
                   {5{SRA}}          & `ALU_SRA    |
                   {5{LUI}}          & `ALU_LUI    |
                   {5{AUIPC}}        & `ALU_AUIPC  |
                   {5{ADDI}}         & `ALU_ADDI   |
                   {5{ANDI}}         & `ALU_ANDI   |
                   {5{ORI}}          & `ALU_ORI    |
                   {5{XORI}}         & `ALU_XORI   |
                   {5{SLLI}}         & `ALU_SLLI   |
                   {5{SRLI}}         & `ALU_SRLI   |
                   {5{SLTI}}         & `ALU_SLTI   |
                   {5{SLTIU}}        & `ALU_SLTIU  |
                   {5{SRAI}}         & `ALU_SRAI   |
                   {5{LB}}           & `MEM_LB     |
                   {5{LH}}           & `MEM_LH     |
                   {5{LW}}           & `MEM_LW     |
                   {5{LBU}}          & `MEM_LBU    |
                   {5{LHU}}          & `MEM_LHU    |
                   {5{SB}}           & `MEM_SB     |
                   {5{SH}}           & `MEM_SH     |
                   {5{SW}}           & `MEM_SW     |
                   {5{MUL}}          & `MUL_MUL    |
                   {5{MULH}}         & `MUL_MULH   |
                   {5{MULHSU}}       & `MUL_MULHU  |
                   {5{MULHU}}        & `MUL_MULHSU |
                   {5{DIV}}          & `DIV_DIV    |
                   {5{DIVU}}         & `DIV_DIVU   |
                   {5{REM}}          & `DIV_REM    |
                   {5{REMU}}         & `DIV_REMU   |
                   {5{BEQ}}          & `JUMP_BEQ   |
                   {5{BNE}}          & `JUMP_BNE   |
                   {5{BLT}}          & `JUMP_BLT   |
                   {5{BGE}}          & `JUMP_BGE   |
                   {5{BLTU}}         & `JUMP_BLTU  |
                   {5{BGEU}}         & `JUMP_BGEU  |
                   {5{JAL}}          & `JUMP_JAL   |
                   {5{JALR}}         & `JUMP_JALR  ;

    wire[4:0] dst = {5{R_valid | I_valid | L_valid | LUI | AUIPC | JAL | JALR}} & rd;
    wire[4:0] src1 = {5{R_valid | I_valid | S_valid | L_valid | B_valid | JALR}} & rs1;
    wire[4:0] src2 = {5{R_valid | S_valid | B_valid}} & rs2;
    wire[2:0] fu1 = RRS[src1];
    wire[2:0] fu2 = RRS[src2];

    assign ImmSel = {3{JALR | L_valid | I_valid}} & `Imm_type_I |
                    {3{B_valid}}                  & `Imm_type_B |
                    {3{JAL}}                      & `Imm_type_J |
                    {3{S_valid}}                  & `Imm_type_S |
                    {3{LUI | AUIPC}}              & `Imm_type_U ;
    
    wire structural_hazard;  
    // always @(*) begin
    //     case (use_ALU)
    //         3'd1:   structural_hazard = RS[`add1][0] == 1 && RS[`add2][0] == 1 && RS[`add3][0] == 1;
    //         3'd2:   structural_hazard = RS[`mem1][0] == 1 && RS[`mem2][0] == 1;
    //         3'd3:   structural_hazard = RS[`mul1][0] == 1 && RS[`mul2][0] == 1;
    //         3'd4:   structural_hazard = RS[`div1][0] == 1;
    //         3'd5:   structural_hazard = RS[`brh1][0] == 1;
    //         default: structural_hazard = 0;
    //     endcase
    // end
    assign structural_hazard = (use_ALU == 3'd1) ? (RS[`add1][0] == 1 && RS[`add2][0] == 1 && RS[`add3][0] == 1) :
                           (use_ALU == 3'd2) ? (RS[`mem1][0] == 1 && RS[`mem2][0] == 1) :
                           (use_ALU == 3'd3) ? (RS[`mul1][0] == 1 && RS[`mul2][0] == 1) :
                           (use_ALU == 3'd4) ? (RS[`div1][0] == 1) :
                           (use_ALU == 3'd5) ? (RS[`brh1][0] == 1) :
                           0;


    reg branch_stall = 0;                            
    assign IS_en = structural_hazard | branch_stall;
    // maintain the table
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            // reset the scoreboard
            for (i = 0; i < 32; i = i + 1) begin
                RRS[i] <= 32'b0;
            end
            for (i = 1; i <= 12; i = i + 1) begin
                RS[i] <= 149'b0;
            end
        end

        else begin
            // my code start
        if(!structural_hazard) begin   //当前指令可以进入RS队列，需要更改RS和RRS对应�?
            case (use_ALU)
                3'd1:  begin
                    if(RS[`add1][`BUSY] == 0) begin
                        RS[`add1][`BUSY] <= 1'b1;
                        RS[`add1][`OP_H:`OP_L] <= op;
                        RS[`add1][`QJ_H:`QJ_L] <= fu1;
                        RS[`add2][`QK_H:`QK_L] <= fu2;
                        RS[`add1][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`add1][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`add1][`IMM_H:`IMM_L] <= imm;
                        RS[`add1][`PC_H:`PC_L] <= PC;
                        RS[`add1][`RD_H:`RD_L] <= dst;
                        RRS[dst] <= `add1;
                    end else if(RS[`add2][`BUSY] == 0) begin
                        RS[`add2][`BUSY] <= 1'b1;
                        RS[`add2][`OP_H:`OP_L] <= op;
                        RS[`add2][`QJ_H:`QJ_L] <= fu1;
                        RS[`add2][`QK_H:`QK_L] <= fu2;
                        RS[`add2][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`add2][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`add2][`IMM_H:`IMM_L] <= imm;
                        RS[`add2][`PC_H:`PC_L] <= PC;
                        RS[`add2][`RD_H:`RD_L] <= dst;
                        RRS[dst] <= `add2;
                    end else begin
                        RS[`add3][`BUSY] <= 1'b1;
                        RS[`add2][`OP_H:`OP_L] <= op;
                        RS[`add3][`QJ_H:`QJ_L] <= fu1;
                        RS[`add3][`QK_H:`QK_L] <= fu2;
                        RS[`add3][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`add3][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`add3][`IMM_H:`IMM_L] <= imm;
                        RS[`add3][`PC_H:`PC_L] <= PC;
                        RS[`add3][`RD_H:`RD_L] <= dst;
                        RRS[dst] <= `add3;
                    end
                end
                3'd2:  begin
                    if(RS[`mul1][`BUSY] == 0) begin
                        RS[`mul1][`BUSY] <= 1'b1;
                        RS[`mul1][`OP_H:`OP_L] <= op;
                        RS[`mul1][`QJ_H:`QJ_L] <= fu1;
                        RS[`mul1][`QK_H:`QK_L] <= fu2;
                        RS[`mul1][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`mul1][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`mul1][`IMM_H:`IMM_L] <= imm;
                        RS[`mul1][`PC_H:`PC_L] <= PC;
                        RS[`mul1][`RD_H:`RD_L] <= rd;
                        RRS[dst] <= `mul1;
                    end else begin
                        RS[`mul2][`BUSY] <= 1'b1;
                        RS[`mul2][`OP_H:`OP_L] <= op;
                        RS[`mul2][`QJ_H:`QJ_L] <= fu1;
                        RS[`mul2][`QK_H:`QK_L] <= fu2;
                        RS[`mul2][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`mul2][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`mul2][`IMM_H:`IMM_L] <= imm;
                        RS[`mul2][`PC_H:`PC_L] <= PC;
                        RS[`mul2][`RD_H:`RD_L] <= rd;
                        RRS[dst] <= `mul2;
                    end  
                end
                3'd3:  begin
                    RS[`div1][`BUSY] <= 1'b1;
                    RS[`div1][`OP_H:`OP_L] <= op;
                    RS[`div1][`QJ_H:`QJ_L] <= fu1;
                    RS[`div1][`QK_H:`QK_L] <= fu2;
                    RS[`div1][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                    RS[`div1][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                    RS[`div1][`IMM_H:`IMM_L] <= imm;
                    RS[`div1][`PC_H:`PC_L] <= PC;
                    RS[`div1][`RD_H:`RD_L] <= rd;
                    RRS[dst] <= `div1;
                end
                3'd4:  begin
                    if(RS[`mem1][`BUSY] == 0) begin
                        RS[`mem1][`BUSY] <= 1'b1;
                        RS[`mem1][`OP_H:`OP_L] <= op;
                        RS[`mem1][`QJ_H:`QJ_L] <= fu1;
                        RS[`mem1][`QK_H:`QK_L] <= fu2;
                        RS[`mem1][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`mem1][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`mem1][`IMM_H:`IMM_L] <= imm;
                        RS[`mem1][`PC_H:`PC_L] <= PC;
                        RS[`mem1][`RD_H:`RD_L] <= rd;
                        RRS[dst] <= `mem1;
                    end else begin
                        RS[`mem2][`BUSY] <= 1'b1;
                        RS[`mem2][`OP_H:`OP_L] <= op;
                        RS[`mem2][`QJ_H:`QJ_L] <= fu1;
                        RS[`mem2][`QK_H:`QK_L] <= fu2;
                        RS[`mem2][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                        RS[`mem2][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                        RS[`mem2][`IMM_H:`IMM_L] <= imm;
                        RS[`mem2][`PC_H:`PC_L] <= PC;
                        RS[`mem2][`RD_H:`RD_L] <= rd;
                        RRS[dst] <= `mem2;
                    end 
                end
                3'd5:  begin
                    RS[`brh1][`BUSY] <= 1'b1;
                    RS[`brh1][`OP_H:`OP_L] <= op;
                    RS[`brh1][`QJ_H:`QJ_L] <= fu1;
                    RS[`brh1][`QK_H:`QK_L] <= fu2;
                    RS[`brh1][`VJ_H:`VJ_L] <= fu1 ? 32'b0 : rs1_val;
                    RS[`brh1][`VK_H:`VK_L] <= fu2 ? 32'b0 : rs2_val;
                    RS[`brh1][`IMM_H:`IMM_L] <= imm;
                    RS[`brh1][`PC_H:`PC_L] <= PC;
                    RS[`brh1][`RD_H:`RD_L] <= rd;
                    RRS[dst] <= `brh1;
                    branch_stall <= 1;
                end
            endcase      
        end

        if(ALU_done != 0 && RS[ALU_done][`BUSY] == 1)begin
            for(i = 0;i < 32;i = i + 1) begin
                if(RRS[i] == ALU_done) RRS[i] <= `RRS_NULL;
            end 
            for(i = 1;i <= 12;i = i + 1) begin
                if(RS[i][`QJ_H:`QJ_L] == ALU_done) begin
                    RS[i][`QJ_H:`QJ_L] <= `Q_NULL;
                    RS[i][`VJ_H:`VJ_L] <= ALU_done_val;
                end 
                if(RS[i][`QK_H:`QK_L] == ALU_done) begin
                RS[i][`QK_H:`QK_L] <= `Q_NULL;
                RS[i][`VK_H:`VK_L] <= ALU_done_val;
                end
            end
            RS[ALU_done][`BUSY] <= 0;
        end
        if(MEM_done != 0 && RS[MEM_done][`BUSY] == 1) begin
            for(i = 0;i < 32;i = i + 1) begin
                if(RRS[i] == MEM_done) RRS[i] <= `RRS_NULL;
            end 
            for(i = 1;i <= 12;i = i + 1) begin
                if(RS[i][`QJ_H:`QJ_L] == MEM_done) begin
                RS[i][`QJ_H:`QJ_L] <= `Q_NULL;
                RS[i][`VJ_H:`VJ_L] <= MEM_done_val;
                end 
                if(RS[i][`QK_H:`QK_L] == MEM_done) begin
                RS[i][`QK_H:`QK_L] <= `Q_NULL;
                RS[i][`VK_H:`VK_L] <= MEM_done_val;
                end
            end
            RS[MEM_done][`BUSY] <= 0;
        end
        if(MUL_done != 0 && RS[MUL_done][`BUSY]) begin
            for(i = 0;i < 32;i = i + 1) begin
                if(RRS[i] == MUL_done) RRS[i] <= `RRS_NULL;
            end 
            for(i = 1;i <= 12;i = i + 1) begin
                if(RS[i][`QJ_H:`QJ_L] == MUL_done) begin
                RS[i][`QJ_H:`QJ_L] <= `Q_NULL;
                RS[i][`VJ_H:`VJ_L] <= MUL_done_val;
                end 
                if(RS[i][`QK_H:`QK_L] == MUL_done) begin
                RS[i][`QK_H:`QK_L] <= `Q_NULL;
                RS[i][`VK_H:`VK_L] <= MUL_done_val;
                end
            end
            RS[MUL_done][`BUSY] <= 0;
        end
        if(DIV_done != 0 && RS[DIV_done][`BUSY]) begin
            for(i = 0;i < 32;i = i + 1) begin
                if(RRS[i] == DIV_done) RRS[i] <= `RRS_NULL;
            end 
            for(i = 1;i <= 12;i = i + 1) begin
                if(RS[i][`QJ_H:`QJ_L] == DIV_done) begin
                RS[i][`QJ_H:`QJ_L] <= `Q_NULL;
                RS[i][`VJ_H:`VJ_L] <= DIV_done_val;
                end 
                if(RS[i][`QK_H:`QK_L] == DIV_done) begin
                RS[i][`QK_H:`QK_L] <= `Q_NULL;
                RS[i][`VK_H:`VK_L] <= DIV_done_val;
                end
            end
            RS[DIV_done][`BUSY] <= 0;
        end
        if(JUMP_done != 0) begin   
            for(i = 0;i < 32;i = i + 1) begin
                if(RRS[i] == JUMP_done) RRS[i] <= `RRS_NULL;
            end
            for(i = 1;i <= 12;i = i + 1) begin
                if(RS[i][`QJ_H:`QJ_L] == JUMP_done) begin
                    RS[i][`QJ_H:`QJ_L] <= `Q_NULL;
                    RS[i][`VJ_H:`VJ_L] <= JUMP_done_val;
                end 
                if(RS[i][`QK_H:`QK_L] == JUMP_done) begin
                    RS[i][`QK_H:`QK_L] <= `Q_NULL;
                    RS[i][`VK_H:`VK_L] <= JUMP_done_val;
                end
            end
            RS[JUMP_done][`BUSY] <= 0;
            branch_stall <= 0;
        end
            //my code end
        end
    end

    // ctrl signals should be combinational logic
    // RO
    always @ (*) begin
        ALU_en1 = 0;
        ALU_en2 = 0;
        ALU_en3 = 0;
        MEM_en1 = 0;
        MEM_en2 = 0;
        MUL_en = 0;
        DIV_en = 0;
        JUMP_en = 0;

            //  JUMP read
            rs1_ctrl_JUMP   = 0;
            rs2_ctrl_JUMP   = 0;
            PC_ctrl_JUMP    = 0;
            imm_ctrl_JUMP   = 0;

            //  ALU read
            rs1_ctrl_ALU1    = 0;
            rs2_ctrl_ALU1   = 0;
            PC_ctrl_ALU1     = 0;
            imm_ctrl_ALU1    = 0;
            rs1_ctrl_ALU2    = 0;
            rs2_ctrl_ALU2    = 0;
            PC_ctrl_ALU2     = 0;
            imm_ctrl_ALU2    = 0;
            rs1_ctrl_ALU3    = 0;
            rs2_ctrl_ALU3    = 0;
            PC_ctrl_ALU3     = 0;
            imm_ctrl_ALU3    = 0;

            //  MEM read
            rs1_ctrl_MEM1    = 0;
            rs2_ctrl_MEM1    = 0;
            imm_ctrl_MEM1    = 0;
            rs1_ctrl_MEM2    = 0;
            rs2_ctrl_MEM2    = 0;
            imm_ctrl_MEM2    = 0;

            //  MUL read
            rs1_ctrl_MUL    = 0;
            rs2_ctrl_MUL    = 0;

            //  DIV read
            rs1_ctrl_DIV    = 0;
            rs2_ctrl_DIV    = 0;

        JUMP_op = 0;
        ALU_op1 = 0;
        ALU_op2 = 0;
        ALU_op3 = 0;
        ALU_use_PC1 = 0;
        ALU_use_imm1 = 0;
        ALU_use_PC2 = 0;
        ALU_use_imm2 = 0;
        ALU_use_PC3 = 0;
        ALU_use_imm3 = 0;
        MEM_we1 = 0;
        MEM_bhw1 = 0;
        MEM_we2 = 0;
        MEM_bhw2 = 0;
        MUL_op = 0;
        DIV_op = 0;

        // JUMP
        if (RS[`brh1][`QJ_H:`QJ_L] == 0 && RS[`brh1][`QK_H:`QK_L] == 0) begin
            JUMP_en         =   1'b1;
            JUMP_op         =   RS[`brh1][`OP_H:`OP_L];     //  FU
            rs1_ctrl_JUMP   =   RS[`brh1][`VJ_H:`VJ_L]; //  RO
            rs2_ctrl_JUMP   =   RS[`brh1][`VK_H:`VK_L];
            PC_ctrl_JUMP    =   RS[`brh1][`PC_H:`PC_L];
            imm_ctrl_JUMP   =   RS[`brh1][`IMM_H:`IMM_L];
            rd_ctrl_JUMP    =   RS[`brh1][`RD_H:`RD_L];
        end 
        // ALU
        if (RS[`add1][`QJ_H:`QJ_L] == 0 && RS[`add1][`QK_H:`QK_L] == 0) begin
            ALU_en1 = 1'b1;
            ALU_op1          =   RS[`add1][`OP_H:`OP_L] == `ALU_AUIPC ? 
                                4'b0001 : RS[`add1][`OP_L+3:`OP_L];
            ALU_use_PC1      =   RS[`add1][`OP_H:`OP_L] == `ALU_AUIPC;
            ALU_use_imm1     =   RS[`add1][`OP_H];          //  FU
            rs1_ctrl_ALU1    =   RS[`add1][`VJ_H:`VJ_L];   //  RO
            rs2_ctrl_ALU1    =   RS[`add1][`VK_H:`VK_L]; 
            PC_ctrl_ALU1     =   RS[`add1][`PC_H:`PC_L]; 
            imm_ctrl_ALU1    =   RS[`add1][`IMM_H:`IMM_L]; 
            rd_ctrl_ALU1    =   RS[`add1][`RD_H:`RD_L];
        end
        if (RS[`add2][`QJ_H:`QJ_L] == 0 && RS[`add2][`QK_H:`QK_L] == 0) begin
            ALU_en2 = 1'b1;
            ALU_op2          =   RS[`add2][`OP_H:`OP_L] == `ALU_AUIPC ? 
                                4'b0001 : RS[`add2][`OP_L+3:`OP_L];
            ALU_use_PC2      =   RS[`add2][`OP_H:`OP_L] == `ALU_AUIPC;
            ALU_use_imm2     =   RS[`add2][`OP_H];          //  FU
            rs1_ctrl_ALU2    =   RS[`add2][`VJ_H:`VJ_L];   //  RO
            rs2_ctrl_ALU2    =   RS[`add2][`VK_H:`VK_L]; 
            PC_ctrl_ALU2     =   RS[`add2][`PC_H:`PC_L]; 
            imm_ctrl_ALU2    =   RS[`add2][`IMM_H:`IMM_L]; 
            rd_ctrl_ALU2    =   RS[`add2][`RD_H:`RD_L];
        end
        if (RS[`add3][`QJ_H:`QJ_L] == 0 && RS[`add3][`QK_H:`QK_L] == 0) begin
            ALU_en3 = 1'b1;
            ALU_op3          =   RS[`add3][`OP_H:`OP_L] == `ALU_AUIPC ? 
                                4'b0001 : RS[`add3][`OP_L+3:`OP_L];
            ALU_use_PC3      =   RS[`add3][`OP_H:`OP_L] == `ALU_AUIPC;
            ALU_use_imm3     =   RS[`add3][`OP_H];          //  FU
            rs1_ctrl_ALU3    =   RS[`add3][`VJ_H:`VJ_L];   //  RO
            rs2_ctrl_ALU3    =   RS[`add3][`VK_H:`VK_L]; 
            PC_ctrl_ALU3     =   RS[`add3][`PC_H:`PC_L]; 
            imm_ctrl_ALU3    =   RS[`add3][`IMM_H:`IMM_L]; 
            rd_ctrl_ALU3    =   RS[`add3][`RD_H:`RD_L];
        end 

        // MEM
        if (RS[`mem1][`QJ_H:`QJ_L] == 0 && RS[`mem1][`QK_H:`QK_L] == 0) begin
            MEM_en1          =   1'b1;
            MEM_we1          =   RS[`mem1][`OP_L];     //  FU
            MEM_bhw1         =   RS[`mem1][`OP_L+3:`OP_L+1];
            rs1_ctrl_MEM1   =   RS[`mem1][`VJ_H:`VJ_L]; //  RO
            rs2_ctrl_MEM1   =   RS[`mem1][`VK_H:`VK_L];
            imm_ctrl_MEM1   =   RS[`mem1][`IMM_H:`IMM_L];
            rd_ctrl_MEM1    =   RS[`mem1][`RD_H:`RD_L];
        end
        if (RS[`mem2][`QJ_H:`QJ_L] == 0 && RS[`mem2][`QK_H:`QK_L] == 0) begin
            MEM_en2          =   1'b1;
            MEM_we2          =   RS[`mem2][`OP_L];     //  FU
            MEM_bhw2         =   RS[`mem2][`OP_L+3:`OP_L+1];
            rs1_ctrl_MEM2   =   RS[`mem2][`VJ_H:`VJ_L]; //  RO
            rs2_ctrl_MEM2   =   RS[`mem2][`VK_H:`VK_L];
            imm_ctrl_MEM2   =   RS[`mem2][`IMM_H:`IMM_L];
            rd_ctrl_MEM2    =   RS[`mem2][`RD_H:`RD_L];
        end

        // MUL
        if (RS[`mul1][`QJ_H:`QJ_L] == 0 && RS[`mul1][`QK_H:`QK_L] == 0) begin
            MUL_en          =   1'b1;                           //  FU
            MUL_op          =   RS[`mul1][`OP_L+2:`OP_L];
            rs1_ctrl_MUL    =   RS[`mul1][`VJ_H:`VJ_L];  //  RO
            rs2_ctrl_MUL    =   RS[`mul1][`VK_H:`VK_L];
            rd_ctrl_MUL     =   RS[`mul1][`RD_H:`RD_L];
        end
        if (RS[`mul2][`QJ_H:`QJ_L] == 0 && RS[`mul2][`QK_H:`QK_L] == 0) begin
            MUL_en          =   1'b1;                           //  FU
            MUL_op          =   RS[`mul2][`OP_L+2:`OP_L];
            rs1_ctrl_MUL    =   RS[`mul2][`VJ_H:`VJ_L];  //  RO
            rs2_ctrl_MUL    =   RS[`mul2][`VK_H:`VK_L];
            rd_ctrl_MUL     =   RS[`mul2][`RD_H:`RD_L];
        end
       
        // DIV
        if (RS[`div1][`QJ_H:`QJ_L] == 0 && RS[`div1][`QK_H:`QK_L] == 0) begin
            DIV_en          =   1'b1;                           //  FU
            DIV_op          =   RS[`div1][`OP_L+1:`OP_L];
            rs1_ctrl_DIV    =   RS[`div1][`VJ_H:`VJ_L];  //  RO
            rs2_ctrl_DIV    =   RS[`div1][`VK_H:`VK_L];
            rd_ctrl_DIV     =   RS[`div1][`RD_H:`RD_L];
        end
    end

    wire[7:0] BCD_ALU_Rs1,  BCD_ALU_Rs2;
    wire[7:0] BCD_MEM_Rs1,  BCD_MEM_Rs2;
    wire[7:0] BCD_MUL_Rs1,  BCD_MUL_Rs2;
    wire[7:0] BCD_DIV_Rs1,  BCD_DIV_Rs2;
    wire[7:0] BCD_JUMP_Rs1, BCD_JUMP_Rs2;

    
    // Bin2BCD ALURs1(.Binary(FUS[`FU_ALU][`SRC1_H:`SRC1_L]), .BCD(BCD_ALU_Rs1));
    // Bin2BCD ALURs2(.Binary(FUS[`FU_ALU][`SRC2_H:`SRC2_L]), .BCD(BCD_ALU_Rs2));

    // Bin2BCD MEMRs1(.Binary(FUS[`FU_MEM][`SRC1_H:`SRC1_L]), .BCD(BCD_MEM_Rs1));
    // Bin2BCD MEMRs2(.Binary(FUS[`FU_MEM][`SRC2_H:`SRC2_L]), .BCD(BCD_MEM_Rs2));

    // Bin2BCD MULRs1(.Binary(FUS[`FU_MUL][`SRC1_H:`SRC1_L]), .BCD(BCD_MUL_Rs1));
    // Bin2BCD MULRs2(.Binary(FUS[`FU_MUL][`SRC2_H:`SRC2_L]), .BCD(BCD_MUL_Rs2));

    // Bin2BCD DIVRs1(.Binary(FUS[`FU_DIV][`SRC1_H:`SRC1_L]), .BCD(BCD_DIV_Rs1));
    // Bin2BCD DIVRs2(.Binary(FUS[`FU_DIV][`SRC2_H:`SRC2_L]), .BCD(BCD_DIV_Rs2));   

    // Bin2BCD JUMPRs1(.Binary(FUS[`FU_JUMP][`SRC1_H:`SRC1_L]), .BCD(BCD_JUMP_Rs1));
    // Bin2BCD JUMPRs2(.Binary(FUS[`FU_JUMP][`SRC2_H:`SRC2_L]), .BCD(BCD_JUMP_Rs2));



    //  VGA Display  (see VGATEST.v line208-246)

    //  |  PC---IF    (32'h-PC)   |  INST-IF  (32'h-Inst) |  PC---IS    (32'h-PC)   |  INST-IS  (32'h-Inst) |

    parameter SEPERATION = 4'HF; 
    //  F is seperation character in the following lines
    
    //  |  1-ALU-I    (32'h-Inst) |  B/D/WAR -FFF-FF-     |  F/R/Q/j  --FF-FF-      |    F/R/Q/k  --FF-FF-  |
    //  |  2-MEM-I    ...
    //  |  3-MUL-I    ...
    //  |  4-DIV-I
    //  |  5-JMP-I

    //  RRS -F-F-F-F
    //  |  R/01-03  |   R/04-07 |   R/08-11 |   R/12-15 |
    //  |  R/16-19  |   R/20-23 |   R/24-27 |   R/28/31 |

    reg[31:0] Test_signal;

    always @* begin
        case (debug_addr[4:0])
            0:  Test_signal = PC_IF;
            1:  Test_signal = inst_IF;
            2:  Test_signal = PC;  
            3:  Test_signal = inst;

            // 4:  Test_signal = ...;
            // 5:  Test_signal = ...;      // 3+1+12+3+1+8+3+1=32
            // 6:  Test_signal = ...;      // 8+8+3+1+8+1+3=32    
            // 7:  Test_signal = ...;      // 8+8+3+1+8+1+3=32  

            // 8:  Test_signal = ...;
            // 9:  Test_signal = ...;      // 3+1+12+3+1+8+3+1=32
            // 10: Test_signal = ...;      // 8+8+3+1+8+1+3=32    
            // 11: Test_signal = ...;      // 8+8+3+1+8+1+3=32  

            // 12: Test_signal = ...;
            // 13: Test_signal = ...;      // 3+1+12+3+1+8+3+1=32
            // 14: Test_signal = ...;      // 8+8+3+1+8+1+3=32    
            // 15: Test_signal = ...;      // 8+8+3+1+8+1+3=32  

            // 16: Test_signal = ...;
            // 17: Test_signal = ...;      // 3+1+12+3+1+8+3+1=32
            // 18: Test_signal = ...;      // 8+8+3+1+8+1+3=32    
            // 19: Test_signal = ...;      // 8+8+3+1+8+1+3=32 

            // 20: Test_signal = ...;
            // 21: Test_signal = ...;      // 3+1+12+3+1+8+3+1=32
            // 22: Test_signal = ...;      // 8+8+3+1+8+1+3=32    
            // 23: Test_signal = ...;      // 8+8+3+1+8+1+3=32     
    
        
            // 24: Test_signal = ...;      //  (1+3+4)*4
            // 25: Test_signal = ...;      //  (1+3+4)*4
            // 26: Test_signal = ...;      //  (1+3+4)*4
            // 27: Test_signal = ...;      //  (1+3+4)*4

            // 28: Test_signal = ...;      //  (1+3+4)*4
            // 29: Test_signal = ...;      //  (1+3+4)*4
            // 30: Test_signal = ...;      //  (1+3+4)*4
            // 31: Test_signal = ...;      //  (1+3+4)*4
            
            default: Test_signal = 32'hAA55_AA55;
        endcase
    end
    assign Testout = Test_signal;
    
endmodule