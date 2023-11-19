# Lab5 Outline

+ PPT上所说，该实验采用scoreboard算法进行顺序发射与乱序执行

+ 该实验中，我们需要实现的是顺序发射与乱序执行的部分，因此我们需要实现的模块有：

  + 顺序发射模块
  + 乱序执行模块
  + 预约站模块
  + 写回模块

+ 基本上来说，CtrlUnit对FU的管理是按照对应的5个Functional Unit的对应编号进行的，包括是否写回、写回的寄存器编号、剩余的倒计时(**cycles**)等变量，都***以对应的FU编号为索引***

## 对一些变量含义的初步猜测

```Verilog
reg[5:0] FU_status; // 0: empty, 1: ALU, 2: MEM, 3: MUL, 4: DIV, 5: JUMP, boolean——FU_status[5]=1代表JUMP模块busy
reg[2:0] reservation_reg [0:31]; //reservation station
reg[4:0] FU_write_to [5:0]; //destination register
reg[5:0] FU_writeback_en; //write back enable
reg[4:0] FU_delay_cycles [5:0]; // delay cycles
reg reg_ID_flush_next; // flush next instruction
```

1. `FU_status`:表示对应模块的busy状态，例如`FU_status[1] == 1'b1`代表Functional Unit 中的ALU模块正在执行指令，处于busy状态，简单理解为一个Boolean数组。

2. `reservation_reg[0]-[31]`:表示reservation station中的32个寄存器，每个寄存器保存当前被预约的FU的编号，例如`reservation_reg[0] == 3'd1`代表reservation station中的第一个寄存器被ALU模块预约。

3. `FU_write_to[0]-[5]`:表示对应模块的写回寄存器编号，例如`FU_write_to[1] == 5'd4`代表ALU模块将结果写回寄存器R4。

4. `FU_writeback_en`:表示对应模块的写回使能，例如`FU_writeback_en[1] == 1'b1`代表ALU模块将结果写回。

5. `FU_delay_cycles[0]-[5]`:表示对应模块的延迟周期，例如`FU_delay_cycles[1] == 5'd2`代表ALU模块需要两个周期才能完成指令，每周期递减。

6. `reg_ID_flush_next`:表示是否需要清空ID阶段的指令，例如`reg_ID_flush_next == 1'b1`代表需要清空ID阶段的指令。

## 对预约站工作模式的猜测

1. 目前的问题在于`reservation_reg`何时进行左移，如果按照PPT上所说每个时钟周期均左移，那么对于需要长时间delay的指令，将会造成提前出预约站，导致后续指令无法正确判断hazard，因此猜测应该是在FU完成指令后才进行左移，更新预约站

> 预约站的更新
+ 预约站的更新模式如何，如何将下一条指令的FU类型更新到预约站中？预约站中不一定为空，此时可能有多条已经预约的指令等待发射(**issue**)，如果当前指令已经成功写回，则可以将其从预约站中清除，也即左移？
+ 预约站中保存的是因为各种hazard无法正常issue的指令，正常发射的指令只需要顺序发射即可，不用进行预约，反正预约了也会立即被左移更新掉。

## 对写回模块的猜测

> 写回逻辑如下
```Verilog
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
            
            //! to fill sth.in
        end
        if (use_FU == 0) begin //  check whether FU is used 
            //! to fill sth.in
        end
        else if (FU_hazard | reg_ID_flush | reg_ID_flush_next) begin
            //! to fill sth.in
        end
        else begin  // regist FU operation
            //! to fill sth.in
            B_in_FU <= B_valid;
            J_in_FU <= JAL | JALR;
        end
    end
end
```
1. 
