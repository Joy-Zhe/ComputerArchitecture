`timescale 1ps/1ps

module HazardDetectionUnit(
    input clk,
    input Branch_ID, rs1use_ID, rs2use_ID,
    input[1:0] hazard_optype_ID,
    input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,
    input cmu_stall,
    output PC_EN_IF, reg_FD_EN, reg_FD_stall, reg_FD_flush,
        reg_DE_EN, reg_DE_flush, reg_EM_EN, reg_EM_flush, reg_MW_EN, reg_MW_flush,
    output forward_ctrl_ls,
    output[1:0] forward_ctrl_A, forward_ctrl_B
);

    // TODO: implement me!
    assign reg_FD_EN = ~cmu_stall;
    assign reg_DE_EN = ~cmu_stall;
    assign reg_EM_EN = ~cmu_stall;
    assign reg_MW_EN = 1'b1;
    assign reg_MW_flush = cmu_stall;

    // hazard_optype[1:0]: 00 for no hazard, 01 for data, 10 for load, 11 for store
    reg [1:0] hazard_optype_EX;
    reg [1:0] hazard_optype_MEM;
    reg [1:0] hazard_optype_WB;
    always @(posedge clk) begin
        if (reg_DE_flush) begin // flush from ID
            hazard_optype_EX <= 2'b00;            
        end
        else begin
            hazard_optype_EX <= hazard_optype_ID; // pass from ID
        end
        hazard_optype_MEM <= hazard_optype_EX; // pass from EX
        hazard_optype_WB <= hazard_optype_MEM; // pass from MEM
    end
   

    // stall 
    wire stall = (hazard_optype_ID != 2'b11) && //ID hazard not store
        (hazard_optype_EX == 2'b10) && rd_EXE && //EXE hazard load(the former instruction is L type)
        (((rd_EXE == rs1_ID) && rs1use_ID) || ((rd_EXE == rs2_ID) && rs2use_ID));

    wire rs1_forward_ED = (hazard_optype_EX == 2'b01) && //EXE hazard data
        ((rd_EXE == rs1_ID) && rd_EXE) && //EXE write to rs1
        (rs1use_ID); //ID read from rs1

    wire rs2_forward_ED = (hazard_optype_EX == 2'b01) && //EXE hazard data
        ((rd_EXE == rs2_ID) && rd_EXE) && //EXE write to rs2
        (rs2use_ID); //ID read from rs2

    wire rs1_forward_MD = (hazard_optype_MEM == 2'b01) && //MEM hazard data
        ((rd_MEM == rs1_ID) && rd_MEM) && //MEM write to rs1
        (rs1use_ID); //ID read from rs1

    wire rs2_forward_MD = (hazard_optype_MEM == 2'b01) && //MEM hazard data
        ((rd_MEM == rs2_ID) && rd_MEM) && //MEM write to rs2
        (rs2use_ID); //ID read from rs2

    wire rs1_forward_LD = (hazard_optype_MEM == 2'b10) && //MEM hazard load
        ((rd_MEM == rs1_ID) && rd_MEM) && //MEM write to rs1
        (rs1use_ID); //ID read from rs1

    wire rs2_forward_LD = (hazard_optype_MEM == 2'b10) && //MEM hazard load
        ((rd_MEM == rs2_ID) && rd_MEM) && //MEM write to rs2
        (rs2use_ID); //ID read from rs2

    // predict not taken
    assign reg_FD_flush = Branch_ID; // branch correct, flush the content in IF/ID

    // stall handling 
    assign reg_FD_stall = stall; // stall
    assign reg_DE_flush = stall; // stall, flush the content in ID/EX
    assign PC_EN_IF = ~stall && ~cmu_stall; // stall, no IF
    
    assign forward_ctrl_A = rs1_forward_ED ? 2'b01 :
                            (rs1_forward_MD ? 2'b10 :
                            (rs1_forward_LD ? 2'b11 : 2'b00));
    assign forward_ctrl_B = rs2_forward_ED ? 2'b01 :
                            (rs2_forward_MD ? 2'b10 :
                            (rs2_forward_LD ? 2'b11 : 2'b00));
    assign forward_ctrl_ls = (rs2_EXE == rd_MEM) && rd_MEM && (hazard_optype_EX == 2'b11) && (hazard_optype_MEM == 2'b10);

endmodule