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
    input[31:0] epc_next, // +4
    output[31:0] PC_redirect,
    output redirect_mux,

    output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, 
    output RegWrite_cancel
);
    // 3 cycles write, record states
    reg[11:0] csr_raddr, csr_waddr; // csr read address, csr write address
    reg[31:0] csr_wdata; // csr write data
    reg csr_w; // 1 represent csr write start
    reg[1:0] csr_wsc; // 

    wire[31:0] mstatus; // mstatus register

    // input: clk, rst, raddr, waddr, wdata, csr_w, csr_wsc_mode
    // output: rdata, mstatus
    CSRRegs csr(
        .clk(clk),
        .rst(rst),
        .csr_w(csr_w),
        .raddr(csr_raddr),
        .waddr(csr_waddr),
        .wdata(csr_wdata),
        .csr_wsc_mode(csr_wsc),

        .rdata(csr_r_data_out),
        .mstatus(mstatus)
        );

    //According to the diagram, design the Exception Unit
    reg [2:0] state;
    reg [31:0] mcause; // mcause value
    reg [31:0] mepc; // mepc value

    parameter STATE0 = 3'b000;
    parameter STATE1 = 3'b001;
    parameter STATE2 = 3'b010;
    parameter STATE3 = 3'b011;
    parameter STATE4 = 3'b100;
    parameter MEPC_addr = 12'h341;    // m mode, address of mepc
    parameter MCAUSE_addr = 12'h342;  // m mode, address of mcause
    parameter MTVAL_addr = 12'h343;   // m mode, address of mtval
    parameter MSTATUS_addr = 12'h300; // m mode, address of mstatus
    parameter MTVEC_addr = 12'h305;   // m mode, address of mtvec

    wire NO_INT = (state == STATE0);
    wire STATE_MEPC = (state == STATE1);
    wire STATE_MCAUSE = (state == STATE2);
    wire STATE_IDLE = (state == STATE3);
    wire CSR_write_END = (state == STATE4);

    wire INT_flag = (interrupt && mstatus[3]) | illegal_inst | l_access_fault | s_access_fault | ecall_m | mret | !NO_INT; // 1 represent csr write start
    // reg [31:0] saved_epc;
    // reg [31:0] saved_epc_next;
    // reg [31:0] EPC;
    reg [2:0] interrupt_type;

    wire INTERRUPT = (interrupt_type == 3'b001);
    wire ILLEGAL_INST = (interrupt_type == 3'b010);
    wire L_ACCESS_FAULT = (interrupt_type == 3'b011);
    wire S_ACCESS_FAULT = (interrupt_type == 3'b100);
    wire ECALL_M = (interrupt_type == 3'b101);
    wire MRET = (interrupt_type == 3'b110);

    always @(posedge INT_flag or posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE0;
        end
        else if(INT_flag && NO_INT) begin // start interrupt
            state <= STATE1;
            //save interrupt type
            if(interrupt && mstatus[3]) begin
                interrupt_type <= 3'b001;
            end
            else if(illegal_inst) begin
                interrupt_type <= 3'b010;
            end
            else if (l_access_fault) begin
                interrupt_type <= 3'b011;
            end
            else if (s_access_fault) begin
                interrupt_type <= 3'b100;
            end
            else if (ecall_m) begin
                interrupt_type <= 3'b101;
            end
            else if (mret) begin
                interrupt_type <= 3'b110;
            end
            else begin
                interrupt_type <= 3'b000;
            end
        end
        else if(STATE_MEPC) begin
            state <= STATE2;
        end
        else if(STATE_MCAUSE) begin
            state <= STATE3;
        end
        else if(STATE_IDLE) begin
            // state <= STATE4;
            state <= STATE0;
        end
    end
    //state machine execution
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            csr_wsc <= 0;
            csr_w <= 0;
            csr_raddr <= 0;
            csr_waddr <= 0;
            csr_wdata <= 0; 
        end
        else if (NO_INT) begin
            // csr_wsc <= csr_wsc_mode_in;
            csr_wsc <= 2'b00;
            csr_w <= csr_rw_in;
            csr_raddr <= csr_rw_addr_in;
            csr_waddr <= csr_rw_addr_in;
            if (csr_w_imm_mux) begin
                csr_wdata <= csr_w_data_imm;
            end
            else begin
                csr_wdata <= csr_w_data_reg;
            end
        end
        else if (STATE_MEPC) begin
            // csr_wsc <= csr_wsc_mode_in;
            csr_wsc <= 2'b00;
            if(!MRET) begin
                csr_w <= 1'b1;                
            end
            else begin
                csr_w <= 1'b0;
            end
            csr_raddr <= MTVEC_addr;
            csr_waddr <= MEPC_addr;
            if (INTERRUPT) begin
                csr_wdata <= epc_next;
            end
            else begin 
                csr_wdata <= epc_cur;
            end
            // mcause for next
            if (INTERRUPT) begin
                mcause <= 32'h0;
            end
            else if (ILLEGAL_INST) begin
                mcause <= 32'h2;
            end
            else if (L_ACCESS_FAULT) begin
                mcause <= 32'h5;
            end
            else if (S_ACCESS_FAULT) begin
                mcause <= 32'h7;
            end
            else if (ECALL_M) begin
                mcause <= 32'hb;
            end
            else if (MRET) begin
                mcause <= 32'h3;
            end
        end
        else if (STATE_MCAUSE) begin
            // csr_wsc <= csr_wsc_mode_in;
            csr_wsc <= 2'b00;
            csr_w <= 1'b1;
            csr_raddr <= csr_rw_addr_in; // no read reqiurement
            csr_waddr <= MCAUSE_addr;
            csr_wdata <= mcause;
        end
        else if (STATE_IDLE) begin
            // csr_wsc <= csr_wsc_mode_in;
            csr_wsc <= 2'b00;
            csr_w <= 1'b1;
            csr_raddr <= MEPC_addr; // no read reqiurement
            csr_waddr <= MSTATUS_addr;
            if (MRET) begin 
                // MPIE: mstatus[7], MIE: mstatus[3]
                csr_wdata <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]}; // mstatus
            end
            else begin
                // save MIE, disable MIE
                csr_wdata <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]}; // mstatus
            end
        end
    end

    // judge if redirect PC
    assign redirect_mux = STATE_MEPC; // if interrupt, redirect mux to PC_redirect
    assign PC_redirect = csr_r_data_out;
    assign RegWrite_cancel = STATE_MEPC;
    assign reg_FD_flush = STATE_MEPC;
    assign reg_DE_flush = STATE_MEPC;
    assign reg_EM_flush = STATE_MEPC;
    assign reg_MW_flush = STATE_MEPC;

endmodule