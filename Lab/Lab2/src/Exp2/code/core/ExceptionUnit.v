`timescale 1ns / 1ps

module ExceptionUnit(
    input clk, rst,
    input csr_rw_in,
    input[1:0] csr_wsc_mode_in,
    input csr_w_imm_mux,
    input[11:0] csr_rw_addr_in,
    input[31:0] csr_w_data_reg,
    input[4:0] csr_w_data_imm,
    output[31:0] csr_r_data_out,

    input interrupt,
    input illegal_inst,
    input l_access_fault,
    input s_access_fault,
    input ecall_m,

    input mret,

    input[31:0] epc_cur,
    input[31:0] epc_next,
    output[31:0] PC_redirect,
    output redirect_mux,

    output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, 
    output RegWrite_cancel
);
    // 3 cycles write, record states
    reg[11:0] csr_raddr, csr_waddr;
    reg[31:0] csr_wdata;
    reg csr_w;
    reg[1:0] csr_wsc;

    wire[31:0] mstatus;

    CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
        .wdata(csr_wdata),.rdata(csr_r_data_out),.mstatus(mstatus),.csr_wsc_mode(csr_wsc));

    //According to the diagram, design the Exception Unit
    
    
    // judge if redirect PC
    assign redirect_mux = interrupt | illegal_inst | l_access_fault | s_access_fault | ecall_m | mret;
    assign PC_redirect = interrupt ? 32'h00000004 : 
                          illegal_inst ? 32'h00000002 : 
                          l_access_fault ? 32'h00000005 : 
                          s_access_fault ? 32'h00000007 : 
                          ecall_m ? 32'h00000008 : 
                          mret ? epc_cur : 32'h00000000; // interrupt vector
    assign RegWrite_cancel = 0;
    assign reg_FD_flush = 0;
    assign reg_DE_flush = 0;
    assign reg_EM_flush = 0;
    assign reg_MW_flush = 0;
endmodule