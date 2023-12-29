`timescale 1ns / 1ps

module  RV32core(
        input debug_en,  // debug enable
        input debug_step,  // debug step clock
        input [6:0] debug_addr,  // debug address
        output[31:0] debug_data,  // debug data
        input clk,  // main clock
        input rst,  // synchronous reset
        input interrupter  // interrupt source, for future use
    );

    wire debug_clk;
    wire[31:0] debug_regs;
    wire[31:0] Test_signal;

    assign debug_data = debug_addr[5] ? Test_signal : debug_regs;
    debug_clk clock(.clk(clk),.debug_en(debug_en),.debug_step(debug_step),.debug_clk(debug_clk));
    wire PC_EN_IF, IS_EN, FU_ALU_EN1,FU_ALU_EN2,FU_ALU_EN3, FU_mem_EN1,FU_mem_EN2, FU_mul_EN1,FU_mul_EN2, FU_div_EN, FU_jump_EN;
    wire[2:0] ImmSel_ctrl, bhw_ctrl;

    //  ALU
    wire RegWrite_ctrl_ALU1,RegWrite_ctrl_ALU2,RegWrite_ctrl_ALU3;
    wire[4:0] rs1_addr_ctrl_ALU1, rs2_addr_ctrl_ALU1, rd_ctrl_ALU1;
    wire[31:0]rs1_data_RO_ALU1, rs2_data_RO_ALU1;
    wire[31:0] PC_ctrl_ALU1,  imm_ctrl_ALU1;
    wire ALUSrcA_ctrl1, ALUSrcB_ctrl1;
    wire[3:0] ALUControl_ctrl1;
    wire[4:0] rs1_addr_ctrl_ALU2, rs2_addr_ctrl_ALU2, rd_ctrl_ALU2;
    wire[31:0]rs1_data_RO_ALU2, rs2_data_RO_ALU2;
    wire[31:0] PC_ctrl_ALU2,  imm_ctrl_ALU2;
    wire ALUSrcA_ctr2l, ALUSrcB_ctrl2;
    wire[3:0] ALUControl_ctrl2;
    wire[4:0] rs1_addr_ctrl_ALU3, rs2_addr_ctrl_ALU3, rd_ctrl_ALU3;
    wire[31:0]rs1_data_RO_ALU3, rs2_data_RO_ALU3;
    wire[31:0] PC_ctrl_ALU3,  imm_ctrl_ALU3;
    wire ALUSrcA_ctrl3, ALUSrcB_ctrl3;
    wire[3:0] ALUControl_ctrl3;

    //  Register file JUMP
    wire RegWrite_ctrl_JUMP;
    wire[4:0] rs1_addr_ctrl_JUMP, rs2_addr_ctrl_JUMP, rd_ctrl_JUMP;
    wire[31:0]rs1_data_RO_JUMP, rs2_data_RO_JUMP;   

    wire[4:0] Jump_ctrl;
    wire[31:0] PC_ctrl_JUMP, imm_ctrl_JUMP;

    //  Register file MEM
    wire RegWrite_ctrl_MEM1;
    wire[4:0] rs1_addr_ctrl_MEM1, rs2_addr_ctrl_MEM1, rd_ctrl_MEM1;
    wire[31:0]rs1_data_RO_MEM1, rs2_data_RO_MEM1;

    wire[31:0] imm_ctrl_MEM1;
    wire mem_w_ctrl1;
    wire RegWrite_ctrl_MEM2;
    wire[4:0] rs1_addr_ctrl_MEM2, rs2_addr_ctrl_MEM2, rd_ctrl_MEM2;
    wire[31:0]rs1_data_RO_MEM2, rs2_data_RO_MEM2;

    wire[31:0] imm_ctrl_MEM2;
    wire mem_w_ctrl2;

    //  Register file MUL
    wire RegWrite_ctrl_MUL1,RegWrite_ctrl_MUL2;
    wire[4:0] rs1_addr_ctrl_MUL1, rs2_addr_ctrl_MUL1, rd_ctrl_MUL1,rs1_addr_ctrl_MUL2, rs2_addr_ctrl_MUL2, rd_ctrl_MUL2;
    wire[31:0]rs1_data_RO_MUL1, rs2_data_RO_MUL1,rs1_data_RO_MUL2, rs2_data_RO_MUL2;

    //  Register file DIV
    wire RegWrite_ctrl_DIV;
    wire[4:0] rs1_addr_ctrl_DIV, rs2_addr_ctrl_DIV, rd_ctrl_DIV;
    wire[31:0]rs1_data_RO_DIV, rs2_data_RO_DIV;
    wire [31:0] PC_IF, next_PC_IF, PC_4_IF, inst_IF;
    wire[31:0]inst_IS, PC_IS, Imm_out_IS;
    wire[31:0]ALUA_RO1, ALUB_RO1,ALUA_RO2, ALUB_RO2,ALUA_RO3, ALUB_RO3;
    wire[3:0] FU_ALU_finish1,FU_ALU_finish2,FU_ALU_finish3, FU_mem_finish1,FU_mem_finish2, FU_mul_finish1, FU_mul_finish2,FU_div_finish, FU_jump_finish;
    wire is_jump_FU;
    wire[31:0] ALUout_FU1, ALUout_FU2, ALUout_FU3, mem_data_FU1, mem_data_FU2, mulres_FU1,mulres_FU2, divres_FU, PC_jump_FU, PC_wb_FU;
    wire[31:0] ALUout_WB1, ALUout_WB2, ALUout_WB3, mem_data_WB1, mem_data_WB2, mulres_WB1,mulres_WB2, divres_WB, PC_wb_WB;
    wire [31:0]rs1_val,rs2_val;

    // IF
    assign PC_EN_IF = IS_EN | (FU_jump_finish!=0) & is_jump_FU;
    REG32 REG_PC(.clk(debug_clk),.rst(rst),.CE(PC_EN_IF),.D(next_PC_IF),.Q(PC_IF));
    add_32 add_IF(.a(PC_IF),.b(32'd4),.c(PC_4_IF));
    MUX2T1_32 mux_IF(.I0(PC_4_IF),.I1(PC_jump_FU),.s((FU_jump_finish!=0) & is_jump_FU),.o(next_PC_IF));
    ROM_D inst_rom(.a(PC_IF[8:2]),.spo(inst_IF));

    //Issue
    REG_IF_IS reg_IF_IS(.clk(debug_clk),.rst(rst),.EN(IS_EN),
        .flush(1'b0),.PCOUT(PC_IF),.IR(inst_IF),
        .IR_IS(inst_IS),.PCurrent_IS(PC_IS));

    ImmGen imm_gen(.ImmSel(ImmSel_ctrl),.inst_field(inst_IS),.Imm_out(Imm_out_IS));

/* 
    assign RegWrite_ctrl_ALU1 = (FU_ALU_finish1 == 4'd1) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_ALU2 = (FU_ALU_finish2 == 4'd2) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_ALU3 = (FU_ALU_finish3 == 4'd3) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_MUL1 = (FU_mul_finish1 == 4'd4) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_MUL2 = (FU_mul_finish2 == 4'd5) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_DIV = (FU_div_finish == 4'd6) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_MEM1 = (FU_mem_finish1 == 4'd7) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_MEM2 = (FU_mem_finish2 == 4'd8) ? 1'b1 : 1'b0;
    assign RegWrite_ctrl_JUMP = (FU_jump_finish == 4'd9) ? 1'b1 : 1'b0; */
    // RO
    Regs register(.clk(debug_clk),.rst(rst),
        //CTRL
        .rs1_addr(inst_IS[19:15]),.rs2_addr(inst_IS[24:20]),
        .rs1_val(rs1_val),.rs2_val(rs2_val),

        //  ALU
        // .R_addr_A_ALU(rs1_addr_ctrl_ALU), .rdata_A_ALU(rs1_data_RO_ALU),    
        // .R_addr_B_ALU(rs2_addr_ctrl_ALU), .rdata_B_ALU(rs2_data_RO_ALU),
        .ALU_finish1(FU_ALU_finish1),
        .Wt_addr_ALU1(rd_ctrl_ALU1), .Wt_data_ALU1(ALUout_FU1),
        
        .ALU_finish2(FU_ALU_finish2),
        .Wt_addr_ALU2(rd_ctrl_ALU2), .Wt_data_ALU2(ALUout_FU2),

        .ALU_finish3(FU_ALU_finish3),
        .Wt_addr_ALU3(rd_ctrl_ALU3), .Wt_data_ALU3(ALUout_FU3),

        //  JUMP
        // .R_addr_A_JUMP(rs1_addr_ctrl_JUMP), .rdata_A_JUMP(rs1_data_RO_JUMP),
        // .R_addr_B_JUMP(rs2_addr_ctrl_JUMP), .rdata_B_JUMP(rs2_data_RO_JUMP),
        .JUMP_finish(FU_jump_finish),
        .Wt_addr_JUMP(rd_ctrl_JUMP), .Wt_data_JUMP(PC_wb_FU),

        //  MEM
        // .R_addr_A_MEM(rs1_addr_ctrl_MEM), .rdata_A_MEM(rs1_data_RO_MEM),
        // .R_addr_B_MEM(rs2_addr_ctrl_MEM), .rdata_B_MEM(rs2_data_RO_MEM),
        .MEM_finish1(FU_mem_finish1),
        .Wt_addr_MEM1(rd_ctrl_MEM1), .Wt_data_MEM1(mem_data_FU1),

        .MEM_finish2(FU_mem_finish2),
        .Wt_addr_MEM2(rd_ctrl_MEM2), .Wt_data_MEM2(mem_data_FU2),

        //  MUL
        // .R_addr_A_MUL(rs1_addr_ctrl_MUL), .rdata_A_MUL(rs1_data_RO_MUL),
        // .R_addr_B_MUL(rs2_addr_ctrl_MUL), .rdata_B_MUL(rs2_data_RO_MUL),
        .MUL_finish1(FU_mul_finish1),
        .Wt_addr_MUL1(rd_ctrl_MUL1), .Wt_data_MUL1(mulres_FU1),
        .MUL_finish2(FU_mul_finish2),
        .Wt_addr_MUL2(rd_ctrl_MUL2), .Wt_data_MUL2(mulres_FU2),

        //  DIV
        // .R_addr_A_DIV(rs1_addr_ctrl_DIV), .rdata_A_DIV(rs1_data_RO_DIV),
        // .R_addr_B_DIV(rs2_addr_ctrl_DIV), .rdata_B_DIV(rs2_data_RO_DIV),
        .DIV_finish1(FU_div_finish),
        .Wt_addr_DIV1(rd_ctrl_DIV), .Wt_data_DIV1(divres_FU),

        .Debug_addr(debug_addr[4:0]),.Debug_regs(debug_regs));

    wire [2:0] bhw_ctrl1, bhw_ctrl2;
    wire [31:0]ALU_done_val,MEM_done_val,MUL_done_val;
    assign ALU_done_val = (FU_ALU_finish1 != 0) ? ALUout_FU1 : (FU_ALU_finish2 != 0) ? ALUout_FU2 :
             (FU_ALU_finish3 != 0) ? ALUout_FU3 : 0;
    assign MEM_done_val = (FU_mem_finish1 != 0) ? mem_data_FU1 : (FU_mem_finish2 != 0) ? mem_data_FU2 : 0;
    assign MUL_done_val = (FU_mul_finish1 != 0) ? mulres_FU1 : (FU_mul_finish2 != 0) ? mulres_FU2 : 0;
   
    CtrlUnit ctrl(.clk(debug_clk),.rst(rst),.PC(PC_IS),.inst(inst_IS),.imm(Imm_out_IS),
        .PC_IF(PC_IF), .inst_IF(inst_IF), .rs1_val(rs1_val) ,.rs2_val(rs2_val),

        .ALU_done(FU_ALU_finish1 | FU_ALU_finish2 | FU_ALU_finish3),.MEM_done(FU_mem_finish1 | FU_mem_finish2),
        .MUL_done(FU_mul_finish1 | FU_mul_finish2),.DIV_done(FU_div_finish),.JUMP_done(FU_jump_finish),
        .ALU_done_val(ALU_done_val),.MEM_done_val(MEM_done_val),
        .MUL_done_val(MUL_done_val),.DIV_done_val(divres_FU),.JUMP_done_val(PC_wb_FU),
        .is_jump(is_jump_FU),
        .IS_en(IS_EN),.ImmSel(ImmSel_ctrl),

        .ALU_en1(FU_ALU_EN1),.ALU_en2(FU_ALU_EN2),.ALU_en3(FU_ALU_EN3),
        .MEM_en1(FU_mem_EN1),.MEM_en2(FU_mem_EN2),.MUL_en1(FU_mul_EN1),.MUL_en2(FU_mul_EN2),
        .DIV_en(FU_div_EN),.JUMP_en(FU_jump_EN),

        //��RS��ȡ����value���źţ�ֱ�Ӵ���FU

        .PC_ctrl_ALU1(PC_ctrl_ALU1),.imm_ctrl_ALU1(imm_ctrl_ALU1),
        .rs1_ctrl_ALU1(rs1_data_RO_ALU1),.rs2_ctrl_ALU1(rs2_data_RO_ALU1),
        .PC_ctrl_ALU2(PC_ctrl_ALU2),.imm_ctrl_ALU2(imm_ctrl_ALU2),
        .rs1_ctrl_ALU2(rs1_data_RO_ALU2),.rs2_ctrl_ALU2(rs2_data_RO_ALU2),
        .PC_ctrl_ALU3(PC_ctrl_ALU3),.imm_ctrl_ALU3(imm_ctrl_ALU3),
        .rs1_ctrl_ALU3(rs1_data_RO_ALU3),.rs2_ctrl_ALU3(rs2_data_RO_ALU3),
        .PC_ctrl_JUMP(PC_ctrl_JUMP),.imm_ctrl_JUMP(imm_ctrl_JUMP),
        .rs1_ctrl_JUMP(rs1_data_RO_JUMP),.rs2_ctrl_JUMP(rs2_data_RO_JUMP),
        .imm_ctrl_MEM1(imm_ctrl_MEM1),
        .rs1_ctrl_MEM1(rs1_data_RO_MEM1),.rs2_ctrl_MEM1(rs2_data_RO_MEM1),
        .imm_ctrl_MEM2(imm_ctrl_MEM2),
        .rs1_ctrl_MEM2(rs1_data_RO_MEM2),.rs2_ctrl_MEM2(rs2_data_RO_MEM2),
        .rs1_ctrl_MUL1(rs1_data_RO_MUL1),.rs2_ctrl_MUL1(rs2_data_RO_MUL1),
        .rs1_ctrl_MUL2(rs1_data_RO_MUL2),.rs2_ctrl_MUL2(rs2_data_RO_MUL2),
        .rs1_ctrl_DIV(rs1_data_RO_DIV),.rs2_ctrl_DIV(rs2_data_RO_DIV),


        .JUMP_op(Jump_ctrl),.ALU_op1(ALUControl_ctrl1),.ALU_op2(ALUControl_ctrl2),.ALU_op3(ALUControl_ctrl3),
        .ALU_use_PC1(ALUSrcA_ctrl1),.ALU_use_imm1(ALUSrcB_ctrl1),
        .ALU_use_PC2(ALUSrcA_ctrl2),.ALU_use_imm2(ALUSrcB_ctrl2),
        .ALU_use_PC3(ALUSrcA_ctrl3),.ALU_use_imm3(ALUSrcB_ctrl3),
        .MEM_we1(mem_w_ctrl1),.MEM_bhw1(bhw_ctrl1),
        .MEM_we2(mem_w_ctrl2),.MEM_bhw2(bhw_ctrl2),
        .MUL_op1(),.MUL_op2(),.DIV_op(),

        //addr ����regster д��
        //.reg_write_JUMP(RegWrite_ctrl_JUMP),
        .rd_ctrl_JUMP(rd_ctrl_JUMP),
        .rd_ctrl_ALU1(rd_ctrl_ALU1),
        .rd_ctrl_ALU2(rd_ctrl_ALU2),
        .rd_ctrl_ALU3(rd_ctrl_ALU3),
        .rd_ctrl_MEM1(rd_ctrl_MEM1),
        .rd_ctrl_MEM2(rd_ctrl_MEM2),
        .rd_ctrl_MUL1(rd_ctrl_MUL1),
        .rd_ctrl_MUL2(rd_ctrl_MUL2),
        .rd_ctrl_DIV(rd_ctrl_DIV),

        .debug_addr(debug_addr[4:0]),
        .Testout(Test_signal)
    );



    MUX2T1_32 mux_imm_ALU_RO_A1(.I0(rs1_data_RO_ALU1),.I1(PC_ctrl_ALU1),.s(ALUSrcA_ctrl1),.o(ALUA_RO1));

    MUX2T1_32 mux_imm_ALU_RO_B1(.I0(rs2_data_RO_ALU1),.I1(imm_ctrl_ALU1),.s(ALUSrcB_ctrl1),.o(ALUB_RO1));

    MUX2T1_32 mux_imm_ALU_RO_A2(.I0(rs1_data_RO_ALU2),.I1(PC_ctrl_ALU2),.s(ALUSrcA_ctrl2),.o(ALUA_RO2));

    MUX2T1_32 mux_imm_ALU_RO_B2(.I0(rs2_data_RO_ALU2),.I1(imm_ctrl_ALU2),.s(ALUSrcB_ctrl2),.o(ALUB_RO2));

    MUX2T1_32 mux_imm_ALU_RO_A3(.I0(rs1_data_RO_ALU3),.I1(PC_ctrl_ALU3),.s(ALUSrcA_ctrl3),.o(ALUA_RO3));

    MUX2T1_32 mux_imm_ALU_RO_B3(.I0(rs2_data_RO_ALU3),.I1(imm_ctrl_ALU3),.s(ALUSrcB_ctrl3),.o(ALUB_RO3));

    // FU
    FU_ALU alu1(.clk(debug_clk),.EN(FU_ALU_EN1),.finish(FU_ALU_finish1),.FU_ID(4'b0001),
        .ALUControl(ALUControl_ctrl1),.ALUA(ALUA_RO1),.ALUB(ALUB_RO1),.res(ALUout_FU1),
        .zero(),.overflow());

    FU_ALU alu2(.clk(debug_clk),.EN(FU_ALU_EN2),.finish(FU_ALU_finish2),.FU_ID(4'b0010),
        .ALUControl(ALUControl_ctrl2),.ALUA(ALUA_RO2),.ALUB(ALUB_RO2),.res(ALUout_FU2),
        .zero(),.overflow());

    FU_ALU alu3(.clk(debug_clk),.EN(FU_ALU_EN3),.finish(FU_ALU_finish3),.FU_ID(4'b0011),
        .ALUControl(ALUControl_ctrl3),.ALUA(ALUA_RO3),.ALUB(ALUB_RO3),.res(ALUout_FU3),
        .zero(),.overflow());

    FU_mem mem1(.clk(debug_clk),.EN(FU_mem_EN1),.finish(FU_mem_finish1),.FU_ID(4'b0111),
        .mem_w(mem_w_ctrl1),.bhw(bhw_ctrl1),.rs1_data(rs1_data_RO_MEM1),.rs2_data(rs2_data_RO_MEM1),
        .imm(imm_ctrl_MEM1),.mem_data(mem_data_FU1));

    FU_mem mem2(.clk(debug_clk),.EN(FU_mem_EN2),.finish(FU_mem_finish2),.FU_ID(4'b1000),
        .mem_w(mem_w_ctrl2),.bhw(bhw_ctrl2),.rs1_data(rs1_data_RO_MEM2),.rs2_data(rs2_data_RO_MEM2),
        .imm(imm_ctrl_MEM2),.mem_data(mem_data_FU2));

    FU_mul mu1(.clk(debug_clk),.EN(FU_mul_EN1),.finish(FU_mul_finish1),.FU_ID(4'b0100),
        .A(rs1_data_RO_MUL1),.B(rs2_data_RO_MUL1),.res(mulres_FU1));
        
    FU_mul mu2(.clk(debug_clk),.EN(FU_mul_EN2),.finish(FU_mul_finish2),.FU_ID(4'b0101),
        .A(rs1_data_RO_MUL2),.B(rs2_data_RO_MUL2),.res(mulres_FU2));

    FU_div du(.clk(debug_clk),.EN(FU_div_EN),.finish(FU_div_finish),.FU_ID(4'b0110),
        .A(rs1_data_RO_DIV),.B(rs2_data_RO_DIV),.res(divres_FU));

    FU_jump ju(.clk(debug_clk),.EN(FU_jump_EN),.finish(FU_jump_finish),.FU_ID(4'b1001),
        .JALR(Jump_ctrl[4]),.cmp_ctrl(Jump_ctrl[3:1]),.rs1_data(rs1_data_RO_JUMP),.rs2_data(rs2_data_RO_JUMP),
        .imm(imm_ctrl_JUMP),.PC(PC_ctrl_JUMP),.PC_jump(PC_jump_FU),.PC_wb(PC_wb_FU),.is_jump(is_jump_FU));

    // WB

    REG32 reg_WB_ALU1(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish1!=0),.D(ALUout_FU1),.Q(ALUout_WB1));       // fill sth. here
    REG32 reg_WB_ALU2(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish2!=0),.D(ALUout_FU2),.Q(ALUout_WB2));       // fill sth. here
    REG32 reg_WB_ALU3(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish3!=0),.D(ALUout_FU3),.Q(ALUout_WB3));       // fill sth. here

    REG32 reg_WB_mem1(.clk(debug_clk),.rst(rst),.CE(FU_mem_finish1!=0),.D(mem_data_FU1),.Q(mem_data_WB1));       // fill sth. here      
    REG32 reg_WB_mem2(.clk(debug_clk),.rst(rst),.CE(FU_mem_finish2!=0),.D(mem_data_FU2),.Q(mem_data_WB2));       // fill sth. here      

    REG32 reg_WB_mul1(.clk(debug_clk),.rst(rst),.CE(FU_mul_finish1!=0),.D(mulres_FU1),.Q(mulres_WB1));       // fill sth. here
    REG32 reg_WB_mul2(.clk(debug_clk),.rst(rst),.CE(FU_mul_finish2!=0),.D(mulres_FU2),.Q(mulres_WB2)); 
     
     
    REG32 reg_WB_div(.clk(debug_clk),.rst(rst),.CE(FU_div_finish!=0),.D(divres_FU),.Q(divres_WB));       // fill sth. here

    REG32 reg_WB_jump(.clk(debug_clk),.rst(rst),.CE(FU_jump_finish!=0),.D(PC_wb_FU),.Q(PC_wb_WB));      // fill sth. here

endmodule