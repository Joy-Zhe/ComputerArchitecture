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
    parameter STATE5 = 3'b101;
    parameter STATE6 = 3'b110;
    parameter MEPC_addr = 12'h341;    // m mode, address of mepc
    parameter MCAUSE_addr = 12'h342;  // m mode, address of mcause
    parameter MTVAL_addr = 12'h343;   // m mode, address of mtval
    parameter MSTATUS_addr = 12'h300; // m mode, address of mstatus
    parameter MTVEC_addr = 12'h305;   // m mode, address of mtvec
    parameter MIE_addr = 12'h304;     // m mode, address of mie
    parameter MIP_addr = 12'h344;     // m mode, address of mip

    wire NO_INT = (state == STATE0);
    wire STATE_MEPC = (state == STATE1);
    wire STATE_MCAUSE = (state == STATE2);
    wire STATE_MRET = (state == STATE3);
    wire STATE_MIE = (state == STATE6);
    wire STATE_MIP = (state == STATE5);
    wire INT_CACHE = (state == STATE4);

    reg [31:0] EPC;
    wire is_exception = illegal_inst || l_access_fault || s_access_fault || ecall_m;
    wire is_interrupt = interrupt && mstatus[3];

    reg saved_reg_FD_flush, saved_reg_DE_flush, saved_reg_EM_flush, saved_reg_MW_flush;
    reg saved_RegWrite_cancel;
    reg saved_redirect_mux;
    reg [31:0] saved_PC_redirect;

    // mcause
    always@(*)begin
        // mcause for next
        if (is_interrupt) begin
            mcause <= 32'h80000000;
        end
        else if (illegal_inst) begin
            mcause <= 32'h2;
        end
        else if (l_access_fault) begin
            mcause <= 32'h5;
        end
        else if (s_access_fault) begin
            mcause <= 32'h7;
        end
        else if (ecall_m) begin
            mcause <= 32'hb;
        end
        else if (mret) begin
            mcause <= 32'h3;
        end
    end

    always @(negedge clk or posedge rst) begin
        if (rst) begin // reset
            state <= STATE0;
        end
        else if(is_exception && NO_INT) begin // start exception
            state <= STATE1;
        end
        else if(is_interrupt && NO_INT) begin // start interrupt
            state <= STATE4; 
        end
        else if(STATE_MEPC) begin
            state <= STATE2; // STATE1 -> STATE2
        end
        // else if(STATE_MCAUSE) begin // STATE2 -> STATE0
        //     state <= STATE0;
        // end
        else if(STATE_MCAUSE) begin
            state <= STATE5; // STATE2 -> STATE5, in handler, continue wirte mie
        end
        else if(STATE_MIP) begin
            state <= STATE6; // STATE5 -> STATE6, in handler, continue wirte mip
        end
        else if(STATE_MIE) begin
            state <= STATE0; // STATE6 -> STATE0, wait for MRET
        end
        else if(STATE_MRET) begin // STATE3 -> STATE0
            state <= STATE0;
        end
        else if(INT_CACHE) begin // STATE4 -> STATE0
            state <= STATE0;
        end
    end
    //state machine execution
    always @(negedge clk) begin
        // init
        saved_redirect_mux <= 1'b0;
        saved_reg_FD_flush <= 1'b0;
        saved_reg_DE_flush <= 1'b0;
        saved_reg_EM_flush <= 1'b0;
        saved_reg_MW_flush <= 1'b0;
        saved_RegWrite_cancel <= 1'b0;
        saved_PC_redirect <= 32'b0;
        csr_raddr <= 12'b0;

        csr_w <= csr_rw_in;
        csr_raddr <= csr_rw_addr_in;
        csr_waddr <= csr_rw_addr_in;

        if(csr_w_imm_mux) begin
            csr_wdata <= {27'b0, csr_w_data_imm[4:0]};
        end
        else begin
            csr_wdata <= csr_w_data_reg;
        end

        csr_wsc <= csr_wsc_mode_in;
        // 
        if (NO_INT) begin
            if (is_exception) begin // exception, save PC, write MSTATUS, read MTVEC
                csr_w <= 1'b1;
                csr_wsc <= 2'b00;
                csr_raddr <= MTVEC_addr;
                csr_waddr <= MSTATUS_addr;
                csr_wdata <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
                EPC <= epc_cur;
                saved_reg_FD_flush <= 1'b1;
                saved_reg_DE_flush <= 1'b1;
                saved_reg_EM_flush <= 1'b1;
                saved_reg_MW_flush <= 1'b1;
                saved_RegWrite_cancel <= 1'b1;
            end
            else if (is_interrupt) begin // interrupt, save PC + 4, write MSTATUS, read MTVEC
                csr_w <= 1'b1;
                csr_wsc <= 2'b00;
                csr_raddr <= MTVEC_addr;
                csr_waddr <= MSTATUS_addr;
                csr_wdata <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
                EPC <= epc_next;
                saved_reg_FD_flush <= 1'b1;
                saved_reg_DE_flush <= 1'b1;
                saved_reg_EM_flush <= 1'b1;
                saved_reg_MW_flush <= 1'b1;
                saved_RegWrite_cancel <= 1'b1;
            end 
            else if (mret) begin // mret, write MSTATUS, PC <= MEPC
                csr_w <= 1'b1;
                csr_wsc <= 2'b00;
                csr_raddr <= MEPC_addr;
                saved_PC_redirect <= csr_r_data_out;
                saved_redirect_mux <= 1'b1;
                saved_reg_FD_flush <= 1'b1;
                saved_reg_DE_flush <= 1'b1;
                saved_reg_EM_flush <= 1'b1;
                saved_reg_MW_flush <= 1'b1;
                saved_RegWrite_cancel <= 1'b1;
            end
        end
        else if (STATE_MEPC) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_raddr <= MTVEC_addr;
            csr_waddr <= MEPC_addr;
            csr_wdata <= EPC;
            saved_PC_redirect <= csr_r_data_out; // jump to MTVEC
            saved_redirect_mux <= 1'b1;
            // flush pipeline
            saved_reg_FD_flush <= 1'b1;
            saved_reg_DE_flush <= 1'b1;
            saved_reg_EM_flush <= 1'b1;
            saved_reg_MW_flush <= 1'b1;
            saved_RegWrite_cancel <= 1'b1;
        end
        else if (STATE_MCAUSE) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MCAUSE_addr;
            csr_wdata <= mcause;
        end
        else if (STATE_MRET) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MSTATUS_addr;
            csr_wdata <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
        end
        else if (STATE_MIE) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MIE_addr;
            // if (is_interrupt) begin // MEIE <= 1
            //     csr_wdata <= 1 << 8;                 
            // end
            // else if (is_exception) begin // MSIE <= 1
            //     csr_wdata <= 1 << 3;
            // end
            csr_wdata <= 32'hfff; // MEIE, MTIE, MSIE
        end
        else if (STATE_MIP) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MIP_addr;
            // if (is_interrupt) begin // MEIP <= 1
            //     csr_wdata <= 1 << 8;
            // end
            // else if (is_exception) begin // MSIP <= 1
            //     csr_wdata <= 1 << 3;
            // end
            csr_wdata <= 32'hfff; // MEIP, MTIP, MSIP
        end
    end

    // judge if redirect PC
    assign redirect_mux = saved_redirect_mux; // if interrupt, redirect mux to PC_redirect
    assign PC_redirect = saved_PC_redirect; // redirect PC
    assign RegWrite_cancel = saved_RegWrite_cancel; // cancel RegWrite
    assign reg_FD_flush = saved_reg_FD_flush;
    assign reg_DE_flush = saved_reg_DE_flush;
    assign reg_EM_flush = saved_reg_EM_flush;
    assign reg_MW_flush = saved_reg_MW_flush;

endmodule