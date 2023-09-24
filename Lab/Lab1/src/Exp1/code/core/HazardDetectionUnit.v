`timescale 1ps/1ps

module HazardDetectionUnit(
    input clk,
    input Branch_ID, rs1use_ID, rs2use_ID,
    input[1:0] hazard_optype_ID,
    input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,
    output PC_EN_IF, reg_FD_EN, reg_FD_stall, reg_FD_flush,
        reg_DE_EN, reg_DE_flush, reg_EM_EN, reg_EM_flush, reg_MW_EN,
    output forward_ctrl_ls,
    output[1:0] forward_ctrl_A, forward_ctrl_B
);
            //according to the diagram, design the Hazard Detection Unit
    assign PC_EN_IF = ~Branch_ID & ~rs1use_ID & ~rs2use_ID & 
        (hazard_optype_ID == 2'b00);
    assign reg_FD_EN = ~Branch_ID & ~rs1use_ID & ~rs2use_ID & 
        (hazard_optype_ID == 2'b00);
    assign reg_FD_stall = (hazard_optype_ID == 2'b01) & 
        ((rd_EXE == rs1_ID) | (rd_EXE == rs2_ID));
    assign reg_FD_flush = (hazard_optype_ID == 2'b10) & 
        ((rd_EXE == rs1_ID) | (rd_EXE == rs2_ID));  
    assign reg_DE_EN = ~Branch_ID & ~rs1use_ID & ~rs2use_ID &
        (hazard_optype_ID == 2'b00);
    assign reg_DE_flush = (hazard_optype_ID == 2'b10) & 
        ((rd_EXE == rs1_ID) | (rd_EXE == rs2_ID));
    assign reg_EM_EN = ~Branch_ID & ~rs1use_ID & ~rs2use_ID &
        (hazard_optype_ID == 2'b00);
    assign reg_EM_flush = (hazard_optype_ID == 2'b10) & 
        ((rd_EXE == rs1_ID) | (rd_EXE == rs2_ID));
    assign reg_MW_EN = ~Branch_ID & ~rs1use_ID & ~rs2use_ID &
        (hazard_optype_ID == 2'b00);
    assign forward_ctrl_ls = (hazard_optype_ID == 2'b01) & 
        ((rd_EXE == rs1_ID) | (rd_EXE == rs2_ID));
    assign forward_ctrl_A = (hazard_optype_ID == 2'b01) &
        (rd_EXE == rs1_ID);
    assign forward_ctrl_B = (hazard_optype_ID == 2'b01) &
        (rd_EXE == rs2_ID);

endmodule