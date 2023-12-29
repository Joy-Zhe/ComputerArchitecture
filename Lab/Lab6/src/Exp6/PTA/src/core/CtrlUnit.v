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
    
    input ALU_done,
    input ALU2_done,
    input MEM_done,
    input MEM2_done,
    input MUL_done,
    input MUL2_done,
    input DIV_done,
    input JUMP_done,
    input is_jump,

    // IF
    output IS_en,

    // IS
    output[2:0] ImmSel,

    // RO/FU
    output reg ALU_en, MEM_en, MUL_en, DIV_en, JUMP_en, ALU2_en, MEM2_en, MUL2_en,
        
            //  ALU
            output reg[31:0] PC_ctrl_ALU,
            output reg[31:0] imm_ctrl_ALU,
            output reg[4:0] rs1_ctrl_ALU, rs2_ctrl_ALU, 

            // ALU2
            output reg[31:0] PC_ctrl_ALU2,
            output reg[31:0] imm_ctrl_ALU2,
            output reg[4:0] rs1_ctrl_ALU2, rs2_ctrl_ALU2,

            //  JUMP
            output reg[31:0] PC_ctrl_JUMP,
            output reg[31:0] imm_ctrl_JUMP,
            output reg[4:0] rs1_ctrl_JUMP, rs2_ctrl_JUMP, 

            //  MEM
            output reg[31:0] imm_ctrl_MEM,
            output reg[4:0] rs1_ctrl_MEM, rs2_ctrl_MEM, 

            //  MEM2
            output reg[31:0] imm_ctrl_MEM2,
            output reg[4:0] rs1_ctrl_MEM2, rs2_ctrl_MEM2,

            //  MUL
            output reg[4:0] rs1_ctrl_MUL, rs2_ctrl_MUL, 

            // MUL2
            output reg[4:0] rs1_ctrl_MUL2, rs2_ctrl_MUL2,

            //  DIV
            output reg[4:0] rs1_ctrl_DIV, rs2_ctrl_DIV, 
    
    // FU
    output reg[4:0] JUMP_op,
    output reg[3:0] ALU_op,
    output reg[3:0] ALU2_op,
    output reg ALU_use_PC,
    output reg ALU2_use_PC,
    output reg ALU_use_imm,
    output reg ALU2_use_imm,
    output reg MEM_we,
    output reg MEM2_we,
    output reg[2:0] MEM_bhw,
    output reg[2:0] MEM2_bhw,
    output reg[2:0] MUL_op,
    output reg[2:0] MUL2_op,
    output reg[1:0] DIV_op,
    
    // WB
            //  ALU
            output reg reg_write_ALU,
            output reg[4:0] rd_ctrl_ALU,

            // ALU2
            output reg reg_write_ALU2,
            output reg[4:0] rd_ctrl_ALU2,

            //  JUMP
            output reg reg_write_JUMP,
            output reg[4:0] rd_ctrl_JUMP,
            
            //  MEM
            output reg reg_write_MEM,
            output reg[4:0] rd_ctrl_MEM,

            // MEM2
            output reg reg_write_MEM2,
            output reg[4:0] rd_ctrl_MEM2,

            //  MUL
            output reg reg_write_MUL,
            output reg[4:0] rd_ctrl_MUL,

            // MUL2
            output reg reg_write_MUL2,
            output reg[4:0] rd_ctrl_MUL2,
            
            //  DIV
            output reg reg_write_DIV,
            output reg[4:0] rd_ctrl_DIV,
    // Debug
    input[4:0] debug_addr,
    output[31:0] Testout
);
    // used in for loop
    integer i;

    reg[31:0] FUS[1:8];
    reg[31:0] IMM[1:8];

    // records which FU will write corresponding reg at WB
    reg[3:0] RRS[0:31]; 

    // sometimes an instruction needs PC to execute
    // pc record
    reg[31:0] PCR[1:8];
    reg[31:0] Inst[1:8];

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

    // wire[6:0] funct7 = inst_IF[31:25];
    // wire[2:0] funct3 = inst_IF[14:12];
    // wire[6:0] opcode = inst_IF[6:0];
    // wire[4:0] rd = inst_IF[11:7];
    // wire[4:0] rs1 = inst_IF[19:15];
    // wire[4:0] rs2 = inst_IF[24:20];

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

    // normal stall: structural hazard or WAW
    // wire structural_hazard = (use_FU == 3'b0 ? 3'b0 : (FUS[use_FU][`BUSY] & !FUS[use_FU][`FU_DONE]));       // fill sth. here
    wire structural_hazard = (use_FU == `FU_ALU) ? structural_hazard_ALU :
                             (use_FU == `FU_MEM) ? structural_hazard_MEM :
                             (use_FU == `FU_MUL) ? structural_hazard_MUL :
                             use_FU == `FU_DIV ? structural_hazard_DIV :
                             use_FU == `FU_JUMP ? structural_hazard_JUMP : 1'b0;

    wire structural_hazard_ALU1 = (FUS[`FU_ALU][`BUSY] & (!FUS[`FU_ALU][`FU_DONE] | ALU_WAR));
    wire structural_hazard_ALU2 = (FUS[`FU_ALU2][`BUSY] & (!FUS[`FU_ALU2][`FU_DONE] | ALU2_WAR));
    wire structural_hazard_ALU = structural_hazard_ALU1 && structural_hazard_ALU2;
    wire structural_hazard_MEM1 = (FUS[`FU_MEM][`BUSY] & (!FUS[`FU_MEM][`FU_DONE] | MEM_WAR));
    wire structural_hazard_MEM2 = (FUS[`FU_MEM2][`BUSY] & (!FUS[`FU_MEM2][`FU_DONE] | MEM2_WAR));
    wire structural_hazard_MEM = structural_hazard_MEM1 && structural_hazard_MEM2;
    wire structural_hazard_MUL1 = (FUS[`FU_MUL][`BUSY] & (!FUS[`FU_MUL][`FU_DONE] | MUL_WAR));
    wire structural_hazard_MUL2 = (FUS[`FU_MUL2][`BUSY] & (!FUS[`FU_MUL2][`FU_DONE] | MUL2_WAR));
    wire structural_hazard_MUL = structural_hazard_MUL1 && structural_hazard_MUL2;
    wire structural_hazard_DIV = FUS[`FU_DIV][`BUSY] & (!FUS[use_FU][`FU_DONE] | DIV_WAR);
    wire structural_hazard_JUMP = FUS[`FU_JUMP][`BUSY] & (!FUS[use_FU][`FU_DONE] | JUMP_WAR);

    wire[3:0] use_FU = {4{use_ALU}}  & `FU_ALU  |
                       {4{use_MEM}}  & `FU_MEM  |
                       {4{use_MUL}}  & `FU_MUL  |
                       {4{use_DIV}}  & `FU_DIV  |
                       {4{use_JUMP}} & `FU_JUMP ;             // fill sth. here                
                             
    // wire waw_hazard = (R_valid | I_valid | L_valid | LUI | AUIPC | JAL | JALR) && RRS[rd]; 
    wire waw_hazard = RRS[dst] != 0 && FUS[RRS[dst]][`FU_DONE] == 0;             // fill sth. here   
                                   
    assign normal_stall = structural_hazard || waw_hazard;          // fill sth. here   


    //  Notice: these two are different
    assign IS_en = IS_flush | (~normal_stall & ~ctrl_stall) || (JUMP_done && is_jump == 0 && use_FU != `FU_JUMP);                // fill sth. here   
    assign RO_en = ~IS_flush & (~normal_stall & ~ctrl_stall) || (JUMP_done && is_jump == 0 && use_FU != `FU_JUMP);                // fill sth. here   

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ctrl_stall <= 0;
        end
        else begin
            // IS
            if (RO_en & (use_FU == `FU_JUMP)) begin
                ctrl_stall <= 1;
            end
            else if (JUMP_done) begin
                ctrl_stall <= 0;
            end
        end
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            IS_flush <= 0;
        end
        else if (JUMP_done & is_jump) begin
            IS_flush <= 1;
        end
        else begin
            IS_flush <= 0;
        end
    end




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
    wire rdy1 = ~|fu1;
    wire rdy2 = ~|fu2;

    assign ImmSel = {3{JALR | L_valid | I_valid}} & `Imm_type_I |
                    {3{B_valid}}                  & `Imm_type_B |
                    {3{JAL}}                      & `Imm_type_J |
                    {3{S_valid}}                  & `Imm_type_S |
                    {3{LUI | AUIPC}}              & `Imm_type_U ;

    // ensure WAR:
    // If an FU hasn't read a register value (RO), don't write to it.
    // WAR = 1  WAR exists
    // WAR = 0  WAR not exist

    wire ALU_WAR = (FUS[`FU_ALU][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1])  ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2])  ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1])  ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2])  ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1])  ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2])  ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_ALU][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2]) 
    );     // fill sth. here
    wire ALU2_WAR = (FUS[`FU_ALU2][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1])  ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2])  ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1])  ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2])  ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1])  ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2])  ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_ALU2][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2]) 
    );
    wire MEM_WAR = (FUS[`FU_MEM][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1]) ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2]) ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1]) ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2]) ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_MEM][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) 
    ); // fill sth. here
    wire MEM2_WAR = (FUS[`FU_MEM2][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1]) ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2]) ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1]) ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2]) ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1]) ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_MEM2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2]) 
    ); // fill sth. here
    wire MUL_WAR = (FUS[`FU_MUL][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1]) ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2]) ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1]) ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2]) ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_MUL][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2])
    );     // fill sth. here
    wire MUL2_WAR = (FUS[`FU_MUL2][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1]) ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2]) ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1]) ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2]) ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1]) ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_MUL2][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2])
    );     // fill sth. here
    wire DIV_WAR = (FUS[`FU_DIV][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1]) ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2]) ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1]) ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2]) ||
        (FUS[`FU_JUMP][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY1]) ||
        (FUS[`FU_JUMP][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_JUMP][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_DIV][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2])
    );     // fill sth. here
    wire JUMP_WAR = (FUS[`FU_JUMP][`DST_H:`DST_L] != 0) && (
        (FUS[`FU_ALU][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY1]) ||
        (FUS[`FU_ALU][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_ALU][`RDY2]) ||
        (FUS[`FU_MEM][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY1]) ||
        (FUS[`FU_MEM][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MEM][`RDY2]) ||
        (FUS[`FU_MUL][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY1]) ||
        (FUS[`FU_MUL][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MUL][`RDY2]) ||
        (FUS[`FU_DIV][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY1]) ||
        (FUS[`FU_DIV][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_DIV][`RDY2]) ||
        (FUS[`FU_ALU2][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY1]) ||
        (FUS[`FU_ALU2][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_ALU2][`RDY2]) ||
        (FUS[`FU_MEM2][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY1]) ||
        (FUS[`FU_MEM2][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MEM2][`RDY2]) ||
        (FUS[`FU_MUL2][`SRC1_H:`SRC1_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY1]) ||
        (FUS[`FU_MUL2][`SRC2_H:`SRC2_L] == FUS[`FU_JUMP][`DST_H:`DST_L] && FUS[`FU_MUL2][`RDY2])
    );     // fill sth. here

    wire [3:0] select_FU = (use_FU == 4'd1) ? (!structural_hazard_ALU1 ? `FU_ALU : `FU_ALU2) :
                           (use_FU == 4'd2) ? (!structural_hazard_MEM1 ? `FU_MEM : `FU_MEM2) :
                           (use_FU == 4'd3) ? (!structural_hazard_MUL1 ? `FU_MUL : `FU_MUL2) :
                            use_FU;


    // maintain the table
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            // reset the scoreboard
            for (i = 0; i < 32; i = i + 1) begin
                RRS[i] <= 4'b0;
            end

            for (i = 1; i <= 8; i = i + 1) begin
                FUS[i] <= 32'b0;
                IMM[i] <= 32'b0;
                PCR[i] <= 32'b0;
                Inst[i] <= 32'b0;
            end
        end

        else begin
            // IS
            if (RO_en) begin
                case (use_FU)
                    4'd1: begin
                        if (!structural_hazard_ALU1) begin
                            if (|dst) RRS[dst] <= `FU_ALU;  // fill sth. here 

                            FUS[`FU_ALU][`BUSY]              <= 1'b1;
                        
                            // fill sth. here
                            FUS[`FU_ALU][`OP_H:`OP_L] <= op;
                            FUS[`FU_ALU][`DST_H:`DST_L] <= dst;
                            FUS[`FU_ALU][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_ALU][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_ALU][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_ALU][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_ALU][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_ALU][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_ALU][`FU_DONE] <= 1'b0;
                            IMM[`FU_ALU] <= imm;
                            PCR[`FU_ALU] <= PC;
                            Inst[`FU_ALU] <= inst;
                        end
                        else begin
                            if (|dst) RRS[dst] <= `FU_ALU2;  // fill sth. here 

                            FUS[`FU_ALU2][`BUSY]              <= 1'b1;
                        
                            // fill sth. here
                            FUS[`FU_ALU2][`OP_H:`OP_L] <= op;
                            FUS[`FU_ALU2][`DST_H:`DST_L] <= dst;
                            FUS[`FU_ALU2][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_ALU2][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_ALU2][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_ALU2][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_ALU2][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_ALU2][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_ALU2][`FU_DONE] <= 1'b0;
                            IMM[`FU_ALU2] <= imm;
                            PCR[`FU_ALU2] <= PC;
                            Inst[`FU_ALU2] <= inst;
                        end
                    end
                    4'd2: begin
                        if (!structural_hazard_MEM1) begin
                            if (|dst) RRS[dst] <= `FU_MEM;  // fill sth. here 
                            
                            FUS[`FU_MEM][`BUSY]              <= 1'b1;

                            // fill sth. here
                            FUS[`FU_MEM][`OP_H:`OP_L] <= op;
                            FUS[`FU_MEM][`DST_H:`DST_L] <= dst;
                            FUS[`FU_MEM][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_MEM][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_MEM][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_MEM][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_MEM][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_MEM][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_MEM][`FU_DONE] <= 1'b0;
                            IMM[`FU_MEM] <= imm;
                            PCR[`FU_MEM] <= PC;
                            Inst[`FU_MEM] <= inst;
                        end
                        else begin
                            if (|dst) RRS[dst] <= `FU_MEM2;  // fill sth. here 
                            
                            FUS[`FU_MEM2][`BUSY]              <= 1'b1;

                            // fill sth. here
                            FUS[`FU_MEM2][`OP_H:`OP_L] <= op;
                            FUS[`FU_MEM2][`DST_H:`DST_L] <= dst;
                            FUS[`FU_MEM2][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_MEM2][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_MEM2][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_MEM2][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_MEM2][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_MEM2][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_MEM2][`FU_DONE] <= 1'b0;
                            IMM[`FU_MEM2] <= imm;
                            PCR[`FU_MEM2] <= PC;
                            Inst[`FU_MEM2] <= inst;
                        end
                    end
                    4'd3: begin
                        if (!structural_hazard_MUL1) begin
                            if (|dst) RRS[dst] <= `FU_MUL;  // fill sth. here

                            FUS[`FU_MUL][`BUSY]              <= 1'b1;

                            // fill sth. here
                            FUS[`FU_MUL][`OP_H:`OP_L] <= op;
                            FUS[`FU_MUL][`DST_H:`DST_L] <= dst;
                            FUS[`FU_MUL][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_MUL][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_MUL][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_MUL][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_MUL][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_MUL][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_MUL][`FU_DONE] <= 1'b0;
                            IMM[`FU_MUL] <= imm;
                            PCR[`FU_MUL] <= PC;
                            Inst[`FU_MUL] <= inst;
                        end 
                        else begin
                            if (|dst) RRS[dst] <= `FU_MUL2;  // fill sth. here

                            FUS[`FU_MUL2][`BUSY]              <= 1'b1;

                            // fill sth. here
                            FUS[`FU_MUL2][`OP_H:`OP_L] <= op;
                            FUS[`FU_MUL2][`DST_H:`DST_L] <= dst;
                            FUS[`FU_MUL2][`SRC1_H:`SRC1_L] <= src1;
                            FUS[`FU_MUL2][`SRC2_H:`SRC2_L] <= src2;
                            FUS[`FU_MUL2][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                            FUS[`FU_MUL2][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                            FUS[`FU_MUL2][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                            FUS[`FU_MUL2][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                            FUS[`FU_MUL2][`FU_DONE] <= 1'b0;
                            IMM[`FU_MUL2] <= imm;
                            PCR[`FU_MUL2] <= PC;
                            Inst[`FU_MUL2] <= inst;
                        end
                    end
                    default: begin
                        // not busy, no WAW, write info to FUS and RRS
                        if (|dst) RRS[dst] <= use_FU;  // fill sth. here 

                        FUS[use_FU][`BUSY]              <= 1'b1;
                        
                        // fill sth. here
                        FUS[use_FU][`OP_H:`OP_L] <= op;
                        FUS[use_FU][`DST_H:`DST_L] <= dst;
                        FUS[use_FU][`SRC1_H:`SRC1_L] <= src1;
                        FUS[use_FU][`SRC2_H:`SRC2_L] <= src2;
                        FUS[use_FU][`FU1_H:`FU1_L] <= FUS[fu1][`FU_DONE] ? 3'b0 : fu1;
                        FUS[use_FU][`FU2_H:`FU2_L] <= FUS[fu2][`FU_DONE] ? 3'b0 : fu2;
                        FUS[use_FU][`RDY1] <= FUS[fu1][`FU_DONE] ? 1'b1 : rdy1;
                        FUS[use_FU][`RDY2] <= FUS[fu2][`FU_DONE] ? 1'b1 : rdy2;
                        FUS[use_FU][`FU_DONE] <= 1'b0;
                        IMM[use_FU] <= imm;
                        PCR[use_FU] <= PC;
                        Inst[use_FU] <= inst;
                    end
                endcase
                
            end

            // RO
            if (FUS[`FU_JUMP][`RDY1] & FUS[`FU_JUMP][`RDY2]) begin
                // JUMP
                FUS[`FU_JUMP][`RDY1] <= 1'b0;
                FUS[`FU_JUMP][`RDY2] <= 1'b0;
                // fill sth. here
            end

            if (FUS[`FU_ALU][`RDY1] & FUS[`FU_ALU][`RDY2]) begin     // fill sth. here.
                // ALU
                FUS[`FU_ALU][`RDY1] <= 1'b0;
                FUS[`FU_ALU][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_ALU2][`RDY1] & FUS[`FU_ALU2][`RDY2]) begin     // fill sth. here.
                // ALU2
                FUS[`FU_ALU2][`RDY1] <= 1'b0;
                FUS[`FU_ALU2][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_MEM][`RDY1] & FUS[`FU_MEM][`RDY2]) begin     // fill sth. here.
                // MEM
                FUS[`FU_MEM][`RDY1] <= 1'b0;
                FUS[`FU_MEM][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_MEM2][`RDY1] & FUS[`FU_MEM2][`RDY2]) begin     // fill sth. here.
                // MEM2
                FUS[`FU_MEM2][`RDY1] <= 1'b0;
                FUS[`FU_MEM2][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_MUL][`RDY1] & FUS[`FU_MUL][`RDY2]) begin     // fill sth. here.
                // MUL
                FUS[`FU_MUL][`RDY1] <= 1'b0;
                FUS[`FU_MUL][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_MUL2][`RDY1] & FUS[`FU_MUL2][`RDY2]) begin     // fill sth. here.
                // MUL2
                FUS[`FU_MUL2][`RDY1] <= 1'b0;
                FUS[`FU_MUL2][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            if (FUS[`FU_DIV][`RDY1] & FUS[`FU_DIV][`RDY2]) begin     // fill sth. here.
                // DIV
                FUS[`FU_DIV][`RDY1] <= 1'b0;
                FUS[`FU_DIV][`RDY2] <= 1'b0;
                // fill sth. here.
            end

            //  EX   
            //  Manage FUS[FU_DONE] here
                //  JUMP
                if (JUMP_done) begin
                   FUS[`FU_JUMP][`FU_DONE] <= JUMP_done; 
                end
                if (ALU_done) begin
                    FUS[`FU_ALU][`FU_DONE]  <= ALU_done;
                end
                if (ALU2_done) begin
                    FUS[`FU_ALU2][`FU_DONE]  <= ALU2_done;
                end
                if (MEM_done) begin
                    FUS[`FU_MEM][`FU_DONE]  <= MEM_done;
                end
                if (MEM2_done) begin
                    FUS[`FU_MEM2][`FU_DONE]  <= MEM2_done;
                end
                if (MUL_done) begin
                    FUS[`FU_MUL][`FU_DONE]  <= MUL_done;
                end
                if (MUL2_done) begin
                    FUS[`FU_MUL2][`FU_DONE]  <= MUL2_done;
                end
                if (DIV_done) begin
                    FUS[`FU_DIV][`FU_DONE]  <= DIV_done;
                end

            // WB

            // JUMP
            if (FUS[`FU_JUMP][`FU_DONE] & ~JUMP_WAR) begin
                if(select_FU != `FU_JUMP || RO_en != 1'b1)
                    FUS[`FU_JUMP] <= 32'b0;
                if(dst != FUS[`FU_JUMP][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_JUMP][`DST_H:`DST_L]] <= 4'b0;                               //fill sth. here
                Inst[`FU_JUMP]                      <=  32'b0;//fill sth. here

                // ensure RAW
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_JUMP) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_JUMP) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end

            if (FUS[`FU_ALU][`FU_DONE] & ~ALU_WAR) begin     // ALU
                if(select_FU != `FU_ALU || RO_en != 1'b1)
                    FUS[`FU_ALU] <= 32'b0;
                if(dst != FUS[`FU_ALU][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_ALU][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_ALU] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_ALU) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_ALU) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
            // ALU2
            if (FUS[`FU_ALU2][`FU_DONE] & ~ALU2_WAR) begin     // ALU2
                if(select_FU != `FU_ALU2 || RO_en != 1'b1)
                    FUS[`FU_ALU2] <= 32'b0;
                if(dst != FUS[`FU_ALU2][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_ALU2][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_ALU2] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_ALU2) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_ALU2) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
            if (FUS[`FU_MEM][`FU_DONE] & ~MEM_WAR) begin     // MEM
                if(select_FU != `FU_MEM || RO_en != 1'b1)
                    FUS[`FU_MEM] <= 32'b0;
                if(dst != FUS[`FU_MEM][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_MEM][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_MEM] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_MEM) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_MEM) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
             if (FUS[`FU_MEM2][`FU_DONE] & ~MEM2_WAR) begin     // MEM
                if(select_FU != `FU_MEM2 || RO_en != 1'b1)
                    FUS[`FU_MEM2] <= 32'b0;
                if(dst != FUS[`FU_MEM2][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_MEM2][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_MEM2] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_MEM2) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_MEM2) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
            if (FUS[`FU_MUL][`FU_DONE] & ~MUL_WAR) begin     // MUL
                if (select_FU != `FU_MUL || RO_en != 1'b1) 
                    FUS[`FU_MUL] <= 32'b0;
                if(dst != FUS[`FU_MUL][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_MUL][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_MUL] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_MUL) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_MUL2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_MUL) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end          //fill sth. here
            if (FUS[`FU_MUL2][`FU_DONE] & ~MUL2_WAR) begin
                if (select_FU != `FU_MUL2 || RO_en != 1'b1) 
                    FUS[`FU_MUL2] <= 32'b0;
                if(dst != FUS[`FU_MUL2][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_MUL2][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_MUL2] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU1_H:`FU1_L] == `FU_MUL2) begin
                    FUS[`FU_DIV][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_DIV][`FU2_H:`FU2_L] == `FU_MUL2) begin
                    FUS[`FU_DIV][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_DIV][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
            if (FUS[`FU_DIV][`FU_DONE] & ~DIV_WAR) begin     // DIV
                if (select_FU != `FU_DIV || RO_en != 1'b1)
                    FUS[`FU_DIV] <= 32'b0; 
                if(dst != FUS[`FU_DIV][`DST_H:`DST_L] || RO_en != 1'b1)
                    RRS[FUS[`FU_DIV][`DST_H:`DST_L]] <= 4'b0;
                Inst[`FU_DIV] <= 32'b0;

                // ensure RAW
                if (FUS[`FU_JUMP][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_JUMP][`RDY1] <= 1'b1;          //fill sth. here    
                    FUS[`FU_JUMP][`FU1_H:`FU1_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_ALU][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_ALU2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_MEM][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_MEM2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_MUL][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL2][`FU1_H:`FU1_L] == `FU_DIV) begin
                    FUS[`FU_MUL2][`RDY1] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL2][`FU1_H:`FU1_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_JUMP][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_JUMP][`RDY2] <= 1'b1;          //fill sth. here
                    FUS[`FU_JUMP][`FU2_H:`FU2_L] <= 4'b0;  //fill sth. here
                end
                if (FUS[`FU_ALU][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_ALU][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_ALU2][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_ALU2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_ALU2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_MEM][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MEM2][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_MEM2][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MEM2][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
                if (FUS[`FU_MUL][`FU2_H:`FU2_L] == `FU_DIV) begin
                    FUS[`FU_MUL][`RDY2] <= 1'b1;            //fill sth. here
                    FUS[`FU_MUL][`FU2_H:`FU2_L] <= 4'b0;    //fill sth. here
                end
            end
        end
    end

    // ctrl signals should be combinational logic
    // RO
    always @ (*) begin
        ALU_en = 0;
        ALU2_en = 0;
        MEM_en = 0;
        MEM2_en = 0;
        MUL_en = 0;
        MUL2_en = 0;
        DIV_en = 0;
        JUMP_en = 0;

            //  JUMP read
            rs1_ctrl_JUMP   = 0;
            rs2_ctrl_JUMP   = 0;
            PC_ctrl_JUMP    = 0;
            imm_ctrl_JUMP   = 0;

            //  ALU read
            rs1_ctrl_ALU    = 0;
            rs2_ctrl_ALU    = 0;
            PC_ctrl_ALU     = 0;
            imm_ctrl_ALU    = 0;

            // ALU2 read
            rs1_ctrl_ALU2   = 0;
            rs2_ctrl_ALU2   = 0;
            PC_ctrl_ALU2    = 0;
            imm_ctrl_ALU2   = 0;

            //  MEM read
            rs1_ctrl_MEM    = 0;
            rs2_ctrl_MEM    = 0;
            imm_ctrl_MEM    = 0;

            // MEM2 read
            rs1_ctrl_MEM2   = 0;
            rs2_ctrl_MEM2   = 0;
            imm_ctrl_MEM2   = 0;

            //  MUL read
            rs1_ctrl_MUL    = 0;
            rs2_ctrl_MUL    = 0;

            // MUL2 read
            rs1_ctrl_MUL2   = 0;
            rs2_ctrl_MUL2   = 0;

            //  DIV read
            rs1_ctrl_DIV    = 0;
            rs2_ctrl_DIV    = 0;

        JUMP_op = 0;
        ALU_op = 0;
        ALU2_op = 0;
        ALU_use_PC = 0;
        ALU2_use_PC = 0;
        ALU_use_imm = 0;
        ALU2_use_imm = 0;
        MEM_we = 0;
        MEM2_we = 0;
        MEM_bhw = 0;
        MEM2_bhw = 0;
        MUL_op = 0;
        MUL2_op = 0;
        DIV_op = 0;

        // JUMP
        if (FUS[`FU_JUMP][`RDY1] & FUS[`FU_JUMP][`RDY2]) begin
            JUMP_en         =   1'b1;
            JUMP_op         =   FUS[`FU_JUMP][`OP_H:`OP_L];     //  FU

            rs1_ctrl_JUMP   =   FUS[`FU_JUMP][`SRC1_H:`SRC1_L]; //  RO
            rs2_ctrl_JUMP   =   FUS[`FU_JUMP][`SRC2_H:`SRC2_L];
            PC_ctrl_JUMP    =   PCR[`FU_JUMP];
            imm_ctrl_JUMP   =   IMM[`FU_JUMP];
        end
        // ALU
        if (FUS[`FU_ALU][`RDY1] & FUS[`FU_ALU][`RDY2]) begin
            ALU_en = 1'b1;
            ALU_op          =   FUS[`FU_ALU][`OP_H:`OP_L] == `ALU_AUIPC ? 
                                4'b0001 : FUS[`FU_ALU][`OP_L+3:`OP_L];
            ALU_use_PC      =   FUS[`FU_ALU][`OP_H:`OP_L] == `ALU_AUIPC;
            ALU_use_imm     =   FUS[`FU_ALU][`OP_H];            //  FU
            
            rs1_ctrl_ALU    =   FUS[`FU_ALU][`SRC1_H:`SRC1_L];  //  RO
            rs2_ctrl_ALU    =   FUS[`FU_ALU][`SRC2_H:`SRC2_L];
            PC_ctrl_ALU     =   PCR[`FU_ALU];
            imm_ctrl_ALU    =   IMM[`FU_ALU];
        end
        // ALU2
        if (FUS[`FU_ALU2][`RDY1] & FUS[`FU_ALU2][`RDY2]) begin
            ALU2_en = 1'b1;
            ALU2_op         =   FUS[`FU_ALU2][`OP_H:`OP_L] == `ALU_AUIPC ? 
                                4'b0001 : FUS[`FU_ALU2][`OP_L+3:`OP_L];
            ALU2_use_PC     =   FUS[`FU_ALU2][`OP_H:`OP_L] == `ALU_AUIPC;
            ALU2_use_imm    =   FUS[`FU_ALU2][`OP_H];           //  FU
            
            rs1_ctrl_ALU2   =   FUS[`FU_ALU2][`SRC1_H:`SRC1_L]; //  RO
            rs2_ctrl_ALU2   =   FUS[`FU_ALU2][`SRC2_H:`SRC2_L];
            PC_ctrl_ALU2    =   PCR[`FU_ALU2];
            imm_ctrl_ALU2   =   IMM[`FU_ALU2];
        end
        // MEM
        if (FUS[`FU_MEM][`RDY1] & FUS[`FU_MEM][`RDY2]) begin
            MEM_en          =   1'b1;                           //  FU
            MEM_we          =   FUS[`FU_MEM][`OP_L];
            MEM_bhw         =   FUS[`FU_MEM][`OP_L+3:`OP_L+1];

            rs1_ctrl_MEM    =   FUS[`FU_MEM][`SRC1_H:`SRC1_L];  //  RO
            rs2_ctrl_MEM    =   FUS[`FU_MEM][`SRC2_H:`SRC2_L];  // if store
            imm_ctrl_MEM    =   IMM[`FU_MEM];
        end
        //MEM2
        if (FUS[`FU_MEM2][`RDY1] & FUS[`FU_MEM2][`RDY2]) begin
            MEM2_en         =   1'b1;                           //  FU
            MEM2_we         =   FUS[`FU_MEM2][`OP_L];
            MEM2_bhw        =   FUS[`FU_MEM2][`OP_L+3:`OP_L+1];

            rs1_ctrl_MEM2   =   FUS[`FU_MEM2][`SRC1_H:`SRC1_L]; //  RO
            rs2_ctrl_MEM2   =   FUS[`FU_MEM2][`SRC2_H:`SRC2_L]; // if store
            imm_ctrl_MEM2   =   IMM[`FU_MEM2];
        end
        // MUL
        if (FUS[`FU_MUL][`RDY1] & FUS[`FU_MUL][`RDY2]) begin
            MUL_en          =   1'b1;                           //  FU
            MUL_op          =   FUS[`FU_MUL][`OP_L+2:`OP_L];

            rs1_ctrl_MUL    =   FUS[`FU_MUL][`SRC1_H:`SRC1_L];  //  RO
            rs2_ctrl_MUL    =   FUS[`FU_MUL][`SRC2_H:`SRC2_L];
        end
        // MUL2
        if (FUS[`FU_MUL2][`RDY1] & FUS[`FU_MUL2][`RDY2]) begin
            MUL2_en         =   1'b1;                           //  FU
            MUL2_op         =   FUS[`FU_MUL2][`OP_L+2:`OP_L];

            rs1_ctrl_MUL2   =   FUS[`FU_MUL2][`SRC1_H:`SRC1_L]; //  RO
            rs2_ctrl_MUL2   =   FUS[`FU_MUL2][`SRC2_H:`SRC2_L];
        end
        // DIV
        if (FUS[`FU_DIV][`RDY1] & FUS[`FU_DIV][`RDY2]) begin
            DIV_en          =   1'b1;                           //  FU
            DIV_op          =   FUS[`FU_DIV][`OP_L+1:`OP_L];

            rs1_ctrl_DIV    =   FUS[`FU_DIV][`SRC1_H:`SRC1_L];  //  RO
            rs2_ctrl_DIV    =   FUS[`FU_DIV][`SRC2_H:`SRC2_L];
        end
    end

    // WB
    always @ (*) begin
        reg_write_ALU   =   0;  //  ALU
        rd_ctrl_ALU     =   0;

        // ALU2
        reg_write_ALU2  =   0;  //  ALU2
        rd_ctrl_ALU2    =   0;

        reg_write_JUMP  =   0;  //  JUMP
        rd_ctrl_JUMP    =   0;

        reg_write_MEM   =   0;  //  MEM
        rd_ctrl_MEM     =   0;

        // MEM2
        reg_write_MEM2  =   0;  //  MEM2
        rd_ctrl_MEM2    =   0;

        reg_write_MUL   =   0;  //  MUL
        rd_ctrl_MUL     =   0;

        // MUL2
        reg_write_MUL2  =   0;  //  MUL2
        rd_ctrl_MUL2    =   0;

        reg_write_DIV   =   0;  //  DIV
        rd_ctrl_DIV     =   0;

        //  WB condition check
        if (FUS[`FU_JUMP][`FU_DONE] & ~JUMP_WAR) begin
            reg_write_JUMP = 1'b1;           //fill sth. here
            rd_ctrl_JUMP = FUS[`FU_JUMP][`DST_H:`DST_L];
        end 

        if (FUS[`FU_ALU][`FU_DONE] & ~ALU_WAR) begin
            reg_write_ALU = 1'b1;           //fill sth. here
            rd_ctrl_ALU = FUS[`FU_ALU][`DST_H:`DST_L];
        end

        if (FUS[`FU_ALU2][`FU_DONE] & ~ALU2_WAR) begin
            reg_write_ALU2 = 1'b1;           //fill sth. here
            rd_ctrl_ALU2 = FUS[`FU_ALU2][`DST_H:`DST_L];
        end

        if (FUS[`FU_MEM][`FU_DONE] & ~MEM_WAR) begin
            reg_write_MEM = 1'b1;           //fill sth. here
            rd_ctrl_MEM = FUS[`FU_MEM][`DST_H:`DST_L];
        end

        if (FUS[`FU_MEM2][`FU_DONE] & ~MEM2_WAR) begin
            reg_write_MEM2 = 1'b1;           //fill sth. here
            rd_ctrl_MEM2 = FUS[`FU_MEM2][`DST_H:`DST_L];
        end

        if (FUS[`FU_MUL][`FU_DONE] & ~MUL_WAR) begin
            reg_write_MUL = 1'b1;           //fill sth. here
            rd_ctrl_MUL = FUS[`FU_MUL][`DST_H:`DST_L];
        end

        if (FUS[`FU_MUL2][`FU_DONE] & ~MUL2_WAR) begin
            reg_write_MUL2 = 1'b1;           //fill sth. here
            rd_ctrl_MUL2 = FUS[`FU_MUL2][`DST_H:`DST_L];
        end

        if (FUS[`FU_DIV][`FU_DONE] & ~DIV_WAR) begin
            reg_write_DIV = 1'b1;           //fill sth. here
            rd_ctrl_DIV = FUS[`FU_DIV][`DST_H:`DST_L];
        end
    end


    wire[7:0] BCD_ALU_Rs1,  BCD_ALU_Rs2;
    wire[7:0] BCD_MEM_Rs1,  BCD_MEM_Rs2;
    wire[7:0] BCD_MUL_Rs1,  BCD_MUL_Rs2;
    wire[7:0] BCD_DIV_Rs1,  BCD_DIV_Rs2;
    wire[7:0] BCD_JUMP_Rs1, BCD_JUMP_Rs2;

    
    Bin2BCD ALURs1(.Binary(FUS[`FU_ALU][`SRC1_H:`SRC1_L]), .BCD(BCD_ALU_Rs1));
    Bin2BCD ALURs2(.Binary(FUS[`FU_ALU][`SRC2_H:`SRC2_L]), .BCD(BCD_ALU_Rs2));

    Bin2BCD MEMRs1(.Binary(FUS[`FU_MEM][`SRC1_H:`SRC1_L]), .BCD(BCD_MEM_Rs1));
    Bin2BCD MEMRs2(.Binary(FUS[`FU_MEM][`SRC2_H:`SRC2_L]), .BCD(BCD_MEM_Rs2));

    Bin2BCD MULRs1(.Binary(FUS[`FU_MUL][`SRC1_H:`SRC1_L]), .BCD(BCD_MUL_Rs1));
    Bin2BCD MULRs2(.Binary(FUS[`FU_MUL][`SRC2_H:`SRC2_L]), .BCD(BCD_MUL_Rs2));

    Bin2BCD DIVRs1(.Binary(FUS[`FU_DIV][`SRC1_H:`SRC1_L]), .BCD(BCD_DIV_Rs1));
    Bin2BCD DIVRs2(.Binary(FUS[`FU_DIV][`SRC2_H:`SRC2_L]), .BCD(BCD_DIV_Rs2));   

    Bin2BCD JUMPRs1(.Binary(FUS[`FU_JUMP][`SRC1_H:`SRC1_L]), .BCD(BCD_JUMP_Rs1));
    Bin2BCD JUMPRs2(.Binary(FUS[`FU_JUMP][`SRC2_H:`SRC2_L]), .BCD(BCD_JUMP_Rs2));



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

            4:  Test_signal = 0;
            5:  Test_signal = 0;      // 3+1+12+3+1+8+3+1=32
            6:  Test_signal = 0;      // 8+8+3+1+8+1+3=32    
            7:  Test_signal = 0;      // 8+8+3+1+8+1+3=32  

            8:  Test_signal = 0;
            9:  Test_signal = 0;      // 3+1+12+3+1+8+3+1=32
            10: Test_signal = 0;      // 8+8+3+1+8+1+3=32    
            11: Test_signal = 0;      // 8+8+3+1+8+1+3=32  

            12: Test_signal = 0;
            13: Test_signal = 0;      // 3+1+12+3+1+8+3+1=32
            14: Test_signal = 0;      // 8+8+3+1+8+1+3=32    
            15: Test_signal = 0;      // 8+8+3+1+8+1+3=32  

            16: Test_signal = 0;
            17: Test_signal = 0;      // 3+1+12+3+1+8+3+1=32
            18: Test_signal = 0;      // 8+8+3+1+8+1+3=32    
            19: Test_signal = 0;      // 8+8+3+1+8+1+3=32 

            20: Test_signal = 0;
            21: Test_signal = 0;      // 3+1+12+3+1+8+3+1=32
            22: Test_signal = 0;      // 8+8+3+1+8+1+3=32    
            23: Test_signal = 0;      // 8+8+3+1+8+1+3=32     
    
        
            24: Test_signal = 0;      //  (1+3+4)*4
            25: Test_signal = 0;      //  (1+3+4)*4
            26: Test_signal = 0;      //  (1+3+4)*4
            27: Test_signal = 0;      //  (1+3+4)*4

            28: Test_signal = 0;      //  (1+3+4)*4
            29: Test_signal = 0;      //  (1+3+4)*4
            30: Test_signal = 0;      //  (1+3+4)*4
            31: Test_signal = 0;      //  (1+3+4)*4
            
            default: Test_signal = 32'hAA55_AA55;
        endcase
    end
    assign Testout = Test_signal;
    
endmodule