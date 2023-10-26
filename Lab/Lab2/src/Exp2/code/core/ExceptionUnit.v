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
    reg[1:0] csr_wsc;

    wire[31:0] mstatus; // mstatus register
    wire [31:0] mepc; // mepc value
    wire [31:0] mtvec; // mtval value

    // input: clk, rst, raddr, waddr, wdata, csr_w, csr_wsc_mode
    // output: rdata, mstatus, mepc, mtvec
    CSRRegs csr(
        .clk(clk),
        .rst(rst),
        .csr_w(csr_w),
        .raddr(csr_raddr),
        .waddr(csr_waddr),
        .wdata(csr_wdata),
        .csr_wsc_mode(csr_wsc),

        .rdata(csr_r_data_out),
        .mstatus(mstatus),
        // add mtvec and mepc read
        .mtvec(mtvec),
        .mepc(mepc)
        );

    //According to the diagram, design the Exception Unit
    reg [2:0] state;
    reg [31:0] mcause = 0; // mcause value
    reg later_INT = 0; // if interrupt and exception happen at the same time, exception is prior
    reg execption_delay = 0; // if exception happen, delay 1 cycle to disable interrupt, get rid of mcause change by interrupt

    parameter STATE0 = 3'b000;
    parameter STATE1 = 3'b001;
    parameter STATE2 = 3'b010;
    parameter STATE3 = 3'b011;
    parameter MEPC_addr = 12'h341;    // m mode, address of mepc
    parameter MCAUSE_addr = 12'h342;  // m mode, address of mcause
    parameter MSTATUS_addr = 12'h300; // m mode, address of mstatus
    parameter MTVEC_addr = 12'h305;   // m mode, address of mtvec

    wire STATE_IDLE = (state == STATE0);
    wire STATE_MSTATUS = (state == STATE1);
    wire STATE_MCAUSE = (state == STATE2);
    wire INT_CACHE = (state == STATE3);

    reg [31:0] EPC;
    reg [31:0] INT_EPC = 0;
    reg saved_int = 1'b0;
    wire is_exception = illegal_inst || l_access_fault || s_access_fault || ecall_m;
    wire is_interrupt = (interrupt || later_INT) && mstatus[3];
    wire jump = (STATE_IDLE && is_interrupt) || (STATE_IDLE && is_exception) || (STATE_IDLE && mret);

    // mcause
    always@(posedge clk)begin
        // mcause for next
        if (illegal_inst) begin
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
        else if (is_interrupt && !execption_delay) begin // lowest priority
            mcause <= 32'h80000000;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin // reset
            state <= STATE0;
        end
        else if(is_exception && STATE_IDLE) begin // start exception
            if (is_interrupt) begin
                later_INT <= 1'b1;
            end else begin
                later_INT <= 1'b0;
            end
            state <= STATE1;
        end
        else if(is_interrupt && STATE_IDLE) begin // start interrupt
            later_INT <= 1'b0;
            INT_EPC <= EPC;
            state <= STATE3; 
        end
        else if(STATE_MSTATUS) begin
            state <= STATE2; // STATE1 -> STATE2
        end
        else if(STATE_MCAUSE) begin
            state <= STATE0;
        end
        else if (INT_CACHE) begin // wait for mepc write, because interrupt is posedge clk triggered
            state <= STATE1;
        end
    end
    //state machine execution
    always @(negedge clk) begin
        EPC <= epc_next;
        if(saved_int == 1'b0) begin
            csr_raddr <= csr_rw_addr_in;
            csr_w <= csr_rw_in;
            csr_waddr <= csr_rw_addr_in;
        end
        else begin
            csr_raddr <= csr_rw_addr_in;
            csr_w <= 1'b1;
            csr_waddr <= MEPC_addr;
            saved_int <= 1'b0;
        end

        if(csr_w_imm_mux) begin
            csr_wdata <= {27'b0, csr_w_data_imm[4:0]};
        end
        else begin
            csr_wdata <= csr_w_data_reg;
        end

        csr_wsc <= csr_wsc_mode_in;
        
        if (STATE_IDLE) begin
            if (is_exception) begin // exception, save PC, write MSTATUS, read MTVEC
                execption_delay <= 1'b1; // delay for a cycle, wait for mstatus[MIE] disable
                csr_w <= 1'b1;
                csr_wsc <= 2'b00;
                csr_waddr <= MEPC_addr;
                csr_wdata <= EPC;
            end
            else if (mret) begin // mret, write MSTATUS, PC <= MEPC
                csr_w <= 1'b1;
                csr_wsc <= 2'b00;
                csr_waddr <= MSTATUS_addr;
                csr_wdata <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
            end
        end
        else if (STATE_MSTATUS) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_raddr <= csr_rw_addr_in;
            csr_waddr <= MSTATUS_addr;
            csr_wdata <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
        end
        else if (STATE_MCAUSE) begin
            execption_delay <= 1'b0;
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MCAUSE_addr;
            csr_wdata <= mcause;
        end
        else if (INT_CACHE) begin
            csr_w <= 1'b1;
            csr_wsc <= 2'b00;
            csr_waddr <= MEPC_addr;
            csr_wdata <= INT_EPC;
            saved_int <= 1'b1;
        end
    end

    assign redirect_mux = jump;
    assign PC_redirect = (STATE_IDLE && is_interrupt) || (STATE_IDLE && is_exception) ? mtvec : ((STATE_IDLE && mret) ? mepc : csr_r_data_out);
    assign RegWrite_cancel = jump;
    assign reg_FD_flush = jump;
    assign reg_DE_flush = jump;
    assign reg_EM_flush = jump;
    assign reg_MW_flush = jump;

endmodule