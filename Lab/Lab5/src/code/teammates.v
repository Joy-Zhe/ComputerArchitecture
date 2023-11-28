    wire WAW = rd_used && (rd == FU_write_to[1] || rd == FU_write_to[2] || rd == FU_write_to[1] ||

                rd == FU_write_to[4] || rd == FU_write_to[5]);             //! to fill sth.in

    wire RAW_rs1 = rs1_use && (rs1 == FU_write_to[1] || rs1 == FU_write_to[2] || rs1 == FU_write_to[1] ||

                rs1 == FU_write_to[4] || rs1 == FU_write_to[5]);              //! to fill sth.in

    wire RAW_rs2 = rs2_use && (rs2 == FU_write_to[1] || rs2 == FU_write_to[2] || rs2 == FU_write_to[1] ||

                rs2 == FU_write_to[4] || rs2 == FU_write_to[5]);              //! to fill sth.in

    wire FU_hazard = (use_FU == 3'd1 && FU_status[1]) || (use_FU == 3'd2 && FU_status[2]) ||

                (use_FU == 3'd3 && FU_status[3]) || (use_FU == 3'd4 && FU_status[4]) ||

                (use_FU == 3'd5 && FU_status[5]) || WAW || RAW_rs1 || RAW_rs2;            //! to fill sth.in



    initial begin

        B_in_FU = 0;

        J_in_FU = 0;

        FU_status <= 6'b0;

        FU_writeback_en <= 6'b0;

        for (i=0; i<32; i=i+1)

    reservation_reg[i] <= 0;

        for (i=0; i<6; i=i+1)

    FU_write_to[i] <= 0;

        FU_delay_cycles[1] <= 5'd1;         // ALU cycles

        FU_delay_cycles[2] <= 5'd2;         // MEM cycles

        FU_delay_cycles[3] <= 5'd7;         // MUL cycles

        FU_delay_cycles[4] <= 5'd24;        // DIV cycles

        FU_delay_cycles[5] <= 5'd2;         // JUMP cycles

        reg_ID_flush_next <= 0;

    end



    always @(posedge clk or posedge rst) begin

        if(rst) begin

            B_in_FU <= 0;

            J_in_FU <= 0;

            FU_status <= 6'b0;

            FU_writeback_en <= 6'b0;

            for (i=0; i<32; i=i+1)

                reservation_reg[i] <= 0;

            for (i=0; i<6; i=i+1)

                FU_write_to[i] <= 0;

            FU_delay_cycles[1] <= 5'd1;         // ALU cycles

            FU_delay_cycles[2] <= 5'd2;         // MEM cycles

            FU_delay_cycles[3] <= 5'd7;         // MUL cycles

            FU_delay_cycles[4] <= 5'd24;        // DIV cycles

            FU_delay_cycles[5] <= 5'd2;         // JUMP cycles

        end

        else begin

            if (reservation_reg[0] != 0) begin  // FU operation write back

               FU_writeback_en[reservation_reg[0]] <= 1'b1;                 //! to fill sth.in

               

            end

            if (use_FU == 0 || rst == 1) begin //  check whether FU is used   nop

                             //! to fill sth.in

            end

            else if (FU_hazard | reg_ID_flush | reg_ID_flush_next) begin   // ?

                             //! to fill sth.in

                end

            else begin  // regist FU operation

                reservation_reg[FU_delay_cycles[use_FU]] <= use_FU;                             //! to fill sth.in

                FU_status[use_FU] <= 1'b1;       

                FU_write_to[use_FU] <=  rd;

                B_in_FU <= B_valid;

                J_in_FU <= JAL | JALR;

            end

            FU_status[reservation_reg[0]] <= 0;

            FU_writeback_en[reservation_reg[0]] <= 0;

            FU_write_to[reservation_reg[0]] <= 0;

            reservation_reg[0] <= reservation_reg[1];

            reservation_reg[1] <= reservation_reg[2];

            reservation_reg[2] <= reservation_reg[3];

            reservation_reg[3] <= reservation_reg[4];

            reservation_reg[4] <= reservation_reg[5];

            reservation_reg[5] <= reservation_reg[6];

            reservation_reg[6] <= reservation_reg[7];

            reservation_reg[7] <= reservation_reg[8];

            reservation_reg[8] <= reservation_reg[9];

            reservation_reg[9] <= reservation_reg[10];

            reservation_reg[10] <= reservation_reg[11];

            reservation_reg[11] <= reservation_reg[12];

            reservation_reg[12] <= reservation_reg[13];

            reservation_reg[13] <= reservation_reg[14];

            reservation_reg[14] <= reservation_reg[15];

            reservation_reg[15] <= reservation_reg[16];

            reservation_reg[16] <= reservation_reg[17];

            reservation_reg[17] <= reservation_reg[18];

            reservation_reg[18] <= reservation_reg[19];

            reservation_reg[19] <= reservation_reg[20];

            reservation_reg[20] <= reservation_reg[21];

            reservation_reg[21] <= reservation_reg[22];

            reservation_reg[22] <= reservation_reg[23];

            reservation_reg[23] <= reservation_reg[24];

            reservation_reg[24] <= reservation_reg[25];

            reservation_reg[25] <= reservation_reg[26];

            reservation_reg[26] <= reservation_reg[27];

            reservation_reg[27] <= reservation_reg[28];

            reservation_reg[28] <= reservation_reg[29];

            reservation_reg[29] <= reservation_reg[30];

            reservation_reg[30] <= reservation_reg[31];

            reservation_reg[31] <= 3'b0;    

        end

    end