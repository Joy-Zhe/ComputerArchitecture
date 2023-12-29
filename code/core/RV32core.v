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
    wire PC_EN_IF, IS_EN, FU_ALU_EN, FU_mem_EN, FU_mul_EN, FU_div_EN, FU_jump_EN;
    wire[2:0] ImmSel_ctrl, bhw_ctrl;

    //  ALU
    wire RegWrite_ctrl_ALU;
    wire[4:0] rs1_addr_ctrl_ALU, rs2_addr_ctrl_ALU, rd_ctrl_ALU;
    wire[31:0]rs1_data_RO_ALU, rs2_data_RO_ALU;
    wire[31:0] PC_ctrl_ALU,  imm_ctrl_ALU;
    wire ALUSrcA_ctrl, ALUSrcB_ctrl;
    wire[3:0] ALUControl_ctrl;

    //  Register file JUMP
    wire RegWrite_ctrl_JUMP;
    wire[4:0] rs1_addr_ctrl_JUMP, rs2_addr_ctrl_JUMP, rd_ctrl_JUMP;
    wire[31:0]rs1_data_RO_JUMP, rs2_data_RO_JUMP;   

    wire[4:0] Jump_ctrl;
    wire[31:0] PC_ctrl_JUMP, imm_ctrl_JUMP;

    //  Register file MEM
    wire RegWrite_ctrl_MEM;
    wire[4:0] rs1_addr_ctrl_MEM, rs2_addr_ctrl_MEM, rd_ctrl_MEM;
    wire[31:0]rs1_data_RO_MEM, rs2_data_RO_MEM;

    wire[31:0] imm_ctrl_MEM;
    wire mem_w_ctrl;

    //  Register file MUL
    wire RegWrite_ctrl_MUL;
    wire[4:0] rs1_addr_ctrl_MUL, rs2_addr_ctrl_MUL, rd_ctrl_MUL;
    wire[31:0]rs1_data_RO_MUL, rs2_data_RO_MUL;

    //  Register file DIV
    wire RegWrite_ctrl_DIV;
    wire[4:0] rs1_addr_ctrl_DIV, rs2_addr_ctrl_DIV, rd_ctrl_DIV;
    wire[31:0]rs1_data_RO_DIV, rs2_data_RO_DIV;
    wire [31:0] PC_IF, next_PC_IF, PC_4_IF, inst_IF;
    wire[31:0]inst_IS, PC_IS, Imm_out_IS;
    wire[31:0]ALUA_RO, ALUB_RO;
    wire[3:0] FU_ALU_finish1,FU_ALU_finish2,FU_ALU_finish3, FU_mem_finish1,FU_mem_finish2, FU_mul_finish, FU_div_finish, FU_jump_finish;
    wire is_jump_FU;
    wire[31:0] ALUout_FU1, ALUout_FU2, ALUout_FU3, mem_data_FU1, mem_data_FU2, mulres_FU, divres_FU, PC_jump_FU, PC_wb_FU;
    wire[31:0] ALUout_WB1, ALUout_WB2, ALUout_WB3, mem_data_WB1, mem_data_WB2, mulres_WB, divres_WB, PC_wb_WB;
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

    // RO
    Regs register(.clk(debug_clk),.rst(rst),
        //CTRL
        .rs1_addr(inst_IS[19:15]),.rs2_addr(inst_IS[24:20]),
        .rs1_val(rs1_val),.rs2_val(rs2_val),

        //  ALU
        // .R_addr_A_ALU(rs1_addr_ctrl_ALU), .rdata_A_ALU(rs1_data_RO_ALU),    
        // .R_addr_B_ALU(rs2_addr_ctrl_ALU), .rdata_B_ALU(rs2_data_RO_ALU),
        .L_S_ALU1(RegWrite_ctrl_ALU1),
        .Wt_addr_ALU1(rd_ctrl_ALU1), .Wt_data_ALU1(ALUout_WB1),
        
        .L_S_ALU2(RegWrite_ctrl_ALU2),
        .Wt_addr_ALU2(rd_ctrl_ALU2), .Wt_data_ALU2(ALUout_WB2),

        .L_S_ALU3(RegWrite_ctrl_ALU3),
        .Wt_addr_ALU3(rd_ctrl_ALU3), .Wt_data_ALU3(ALUout_WB3),

        //  JUMP
        // .R_addr_A_JUMP(rs1_addr_ctrl_JUMP), .rdata_A_JUMP(rs1_data_RO_JUMP),
        // .R_addr_B_JUMP(rs2_addr_ctrl_JUMP), .rdata_B_JUMP(rs2_data_RO_JUMP),
        .L_S_JUMP(RegWrite_ctrl_JUMP),
        .Wt_addr_JUMP(rd_ctrl_JUMP), .Wt_data_JUMP(PC_wb_WB),

        //  MEM
        // .R_addr_A_MEM(rs1_addr_ctrl_MEM), .rdata_A_MEM(rs1_data_RO_MEM),
        // .R_addr_B_MEM(rs2_addr_ctrl_MEM), .rdata_B_MEM(rs2_data_RO_MEM),
        .L_S_MEM1(RegWrite_ctrl_MEM1),
        .Wt_addr_MEM1(rd_ctrl_MEM1), .Wt_data_MEM1(mem_data_WB1),

        .L_S_MEM2(RegWrite_ctrl_MEM2),
        .Wt_addr_MEM2(rd_ctrl_MEM2), .Wt_data_MEM2(mem_data_WB2),

        //  MUL
        // .R_addr_A_MUL(rs1_addr_ctrl_MUL), .rdata_A_MUL(rs1_data_RO_MUL),
        // .R_addr_B_MUL(rs2_addr_ctrl_MUL), .rdata_B_MUL(rs2_data_RO_MUL),
        .L_S_MUL1(RegWrite_ctrl_MUL),
        .Wt_addr_MUL1(rd_ctrl_MUL), .Wt_data_MUL1(mulres_WB),

        //  DIV
        // .R_addr_A_DIV(rs1_addr_ctrl_DIV), .rdata_A_DIV(rs1_data_RO_DIV),
        // .R_addr_B_DIV(rs2_addr_ctrl_DIV), .rdata_B_DIV(rs2_data_RO_DIV),
        .L_S_DIV1(RegWrite_ctrl_DIV),
        .Wt_addr_DIV1(rd_ctrl_DIV), .Wt_data_DIV1(divres_WB),

        .Debug_addr(debug_addr[4:0]),.Debug_regs(debug_regs));

    CtrlUnit ctrl(.clk(debug_clk),.rst(rst),.PC(PC_IS),.inst(inst_IS),.imm(Imm_out_IS),
        .PC_IF(PC_IF), .inst_IF(inst_IF), .rs1_val(rs1_val) ,.rs2_val(rs2_val),

        .ALU_done(FU_ALU_finish1 | FU_ALU_finish2 | FU_ALU_finish3),.MEM_done(FU_mem_finish1 | FU_mem_finish2),
        .MUL_done(FU_mul_finish),.DIV_done(FU_div_finish),.JUMP_done(FU_jump_finish),
        .ALU_done_val(ALUout_FU1 | ALUout_FU2 | ALUout_FU3),.MEM_done_val(mem_data_FU1 | mem_data_FU2),
        .MUL_done_val(mulres_FU),.DIV_done_val(divres_FU),.JUMP_done_val(PC_wb_FU),
        .is_jump(is_jump_FU),
        .IS_en(IS_EN),.ImmSel(ImmSel_ctrl),

        .ALU_en1(FU_ALU_EN1),.ALU_en2(FU_ALU_EN2),.ALU_en3(FU_ALU_EN3),
        .MEM_en1(FU_mem_EN1),.MEM_en2(FU_mem_EN2),.MUL_en(FU_mul_EN),.DIV_en(FU_div_EN),.JUMP_en(FU_jump_EN),

        //从RS中取出的value和信号，直接传给FU

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
        .rs1_ctrl_MUL(rs1_data_RO_MUL),.rs2_ctrl_MUL(rs2_data_RO_MUL),
        .rs1_ctrl_DIV(rs1_data_RO_DIV),.rs2_ctrl_DIV(rs2_data_RO_DIV),


        .JUMP_op(Jump_ctrl),.ALU_op1(ALUControl_ctrl1),.ALU_op2(ALUControl_ctrl2),.ALU_op3(ALUControl_ctrl3),
        .ALU_use_PC1(ALUSrcA_ctrl1),.ALU_use_imm1(ALUSrcB_ctrl1),
        .ALU_use_PC2(ALUSrcA_ctrl2),.ALU_use_imm2(ALUSrcB_ctrl2),
        .ALU_use_PC3(ALUSrcA_ctrl3),.ALU_use_imm3(ALUSrcB_ctrl3),
        .MEM_we1(mem_w_ctrl1),.MEM_bhw1(bhw_ctrl1),
        .MEM_we2(mem_w_ctrl2),.MEM_bhw2(bhw_ctrl2),
        .MUL_op(),.DIV_op(),

        //addr 传给regster 写回
        .reg_write_JUMP(RegWrite_ctrl_JUMP),.rd_ctrl_JUMP(rd_ctrl_JUMP),
        .reg_write_ALU1(RegWrite_ctrl_ALU1),  .rd_ctrl_ALU1(rd_ctrl_ALU1),
        .reg_write_ALU2(RegWrite_ctrl_ALU2),  .rd_ctrl_ALU2(rd_ctrl_ALU2),
        .reg_write_ALU3(RegWrite_ctrl_ALU3),  .rd_ctrl_ALU3(rd_ctrl_ALU3),
        .reg_write_MEM1(RegWrite_ctrl_MEM1),  .rd_ctrl_MEM1(rd_ctrl_MEM1),
        .reg_write_MEM2(RegWrite_ctrl_MEM2),  .rd_ctrl_MEM2(rd_ctrl_MEM2),
        .reg_write_MUL(RegWrite_ctrl_MUL),  .rd_ctrl_MUL(rd_ctrl_MUL),
        .reg_write_DIV(RegWrite_ctrl_DIV),  .rd_ctrl_DIV(rd_ctrl_DIV),

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
    FU_ALU alu1(.clk(debug_clk),.EN(FU_ALU_EN1),.finish(FU_ALU_finish1),
        .ALUControl(ALUControl_ctrl1),.ALUA(ALUA_RO1),.ALUB(ALUB_RO1),.res(ALUout_FU1),
        .zero(),.overflow());

    FU_ALU alu2(.clk(debug_clk),.EN(FU_ALU_EN2),.finish(FU_ALU_finish2),
        .ALUControl(ALUControl_ctrl2),.ALUA(ALUA_RO2),.ALUB(ALUB_RO2),.res(ALUout_FU2),
        .zero(),.overflow());

    FU_ALU alu3(.clk(debug_clk),.EN(FU_ALU_EN3),.finish(FU_ALU_finish3),
        .ALUControl(ALUControl_ctrl3),.ALUA(ALUA_RO3),.ALUB(ALUB_RO3),.res(ALUout_FU3),
        .zero(),.overflow());

    FU_mem mem1(.clk(debug_clk),.EN(FU_mem_EN1),.finish(FU_mem_finish1),
        .mem_w(mem_w_ctrl1),.bhw(bhw_ctrl1),.rs1_data(rs1_data_RO_MEM1),.rs2_data(rs2_data_RO_MEM1),
        .imm(imm_ctrl_MEM1),.mem_data(mem_data_FU1));

    FU_mem mem2(.clk(debug_clk),.EN(FU_mem_EN2),.finish(FU_mem_finish2),
        .mem_w(mem_w_ctrl2),.bhw(bhw_ctrl2),.rs1_data(rs1_data_RO_MEM2),.rs2_data(rs2_data_RO_MEM2),
        .imm(imm_ctrl_MEM2),.mem_data(mem_data_FU2));

    FU_mul mu(.clk(debug_clk),.EN(FU_mul_EN),.finish(FU_mul_finish),
        .A(rs1_data_RO_MUL),.B(rs2_data_RO_MUL),.res(mulres_FU));

    FU_div du(.clk(debug_clk),.EN(FU_div_EN),.finish(FU_div_finish),
        .A(rs1_data_RO_DIV),.B(rs2_data_RO_DIV),.res(divres_FU));

    FU_jump ju(.clk(debug_clk),.EN(FU_jump_EN),.finish(FU_jump_finish),
        .JALR(Jump_ctrl[4]),.cmp_ctrl(Jump_ctrl[3:0]),.rs1_data(rs1_data_RO_JUMP),.rs2_data(rs2_data_RO_JUMP),
        .imm(imm_ctrl_JUMP),.PC(PC_ctrl_JUMP),.PC_jump(PC_jump_FU),.PC_wb(PC_wb_FU),.is_jump(is_jump_FU));

    // WB

    REG32 reg_WB_ALU1(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish1!=0),.D(ALUout_FU1),.Q(ALUout_WB1));       // fill sth. here
    REG32 reg_WB_ALU2(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish2!=0),.D(ALUout_FU2),.Q(ALUout_WB2));       // fill sth. here
    REG32 reg_WB_ALU3(.clk(debug_clk),.rst(rst),.CE(FU_ALU_finish3!=0),.D(ALUout_FU3),.Q(ALUout_WB3));       // fill sth. here

    REG32 reg_WB_mem1(.clk(debug_clk),.rst(rst),.CE(FU_mem_finish1!=0),.D(mem_data_FU1),.Q(mem_data_WB1));       // fill sth. here      
    REG32 reg_WB_mem2(.clk(debug_clk),.rst(rst),.CE(FU_mem_finish2!=0),.D(mem_data_FU2),.Q(mem_data_WB2));       // fill sth. here      

    REG32 reg_WB_mul(.clk(debug_clk),.rst(rst),.CE(FU_mul_finish!=0),.D(mulres_FU),.Q(mulres_WB));       // fill sth. here

    REG32 reg_WB_div(.clk(debug_clk),.rst(rst),.CE(FU_div_finish!=0),.D(divres_FU),.Q(divres_WB));       // fill sth. here

    REG32 reg_WB_jump(.clk(debug_clk),.rst(rst),.CE(FU_jump_finish!=0),.D(PC_wb_FU),.Q(PC_wb_WB));      // fill sth. here

endmodule