# Lab1 REPORT

## I. Experiment Purpose

1. Understand RISC-V RV32I instructions 
2. Master the design methods of pipelined CPU executing RV32I instructions
3. Master the method of Pipeline Forwarding Detection and bypass unit design
4. Master the methods of 1-cycle stall of Predict-not-taken branch design
5. Master methods of program verification of Pipelined CPU executing RV32I instructions

## II. Experiment Task 

+ Design of Pipelined CPU executing RV32I instructions
	1. Design datapath 
	2. Design Bypass Unit 
	3. Design CPU Controller 
	4. Verify the Pipelined CPU with program and observe the execution of program 

## III. Basic Principle


### Hazard Types
1. Structure Hazard
2. Data Hazard
3. Control Hazard
+ But for forward(bypass), we can re-classify them to these 3 types:
1. Operation without Memory read or Write
	+ these operations only 
2. Load from Memory
3. Write back to Memory


4. `R type`, `I type`, `JAL`, `JALR`, `LUI`, `AUPIC`
5. `L type`
6. `S type`

### Hazard Solution
1. 无法规避的Stall
+ 必须要stall的情况比较少，仅在前一指令为`Load`指令时才会发生。(`store`虽然也访存，但是寄存器的值是已经存在的)
+ 假设Load指令正在从内存中向寄存器`r_n`读取数据（**WB**），而下一指令又要取用`r_n`（**ID**），即`Load`跟着`R type`, `I type`, `JAL`, `JALR`, `AUPIC`, `LUI`, `B type`这些需要在ID阶段读取**同一寄存器值**的指令时，无法避免的需要一个`stall`，因此可以通过检测前一指令是否为`L type`来规避可能发生的`data hazard`, 进而能将前一指令`MEM`阶段读取到的寄存器值`forward`到当前指令的`EX`阶段
2. 直接Forward
+ 这种情况也需要分为两类
	1. 前一条为`L type`下一条为`S type`，此种情况在两个指令的`MEM`阶段进行`forward`
	2. 非`L type`与`S type` 指令，寄存器占用导致的forward，寄存器值可以从上上个MEM阶段到当前EX阶段，也可以从上一个EX阶段到当前EX阶段
3. Control Hazard
	1. 对于跳转指令，采取Predict Not Taken策略，即对于即将发生的跳转指令，默认其不执行跳转，先继续执行，如果发现判断出的信号正确，则进行flush，将正在进行的取指全部清空。
	> 因为branch指令在ID阶段就能得知当前信号是否正确，而下一条指令此时刚刚取指，可以通过flush将错误执行的指令停止

### Predict-not-taken
+ 见上

### Forward Types
1. $EXE\rightarrow next\ EXE$
2. $MEM\rightarrow next\ 2\ EXE$
3. $MEM_{read}\rightarrow next\ MEM_{write}$
4. 
## IV. Operating Procedures

1. **CtrlUnit**
+ Operation type detection:
```Verilog
	wire BEQ = Bop & funct3_0;                            //to fill sth. in
    wire BNE = Bop & funct3_1;                            //to fill sth. in
    wire BLT = Bop & funct3_4;                            //to fill sth. in
    wire BGE = Bop & funct3_5;                            //to fill sth. in
    wire BLTU = Bop & funct3_6;                           //to fill sth. in
    wire BGEU = Bop & funct3_7;                           //to fill sth. in
    
    wire LB = Lop & funct3_0;                            //to fill sth. in
    wire LH = Lop & funct3_1;                            //to fill sth. in
    wire LW = Lop & funct3_2;                            //to fill sth. in
    wire LBU = Lop & funct3_4;                            //to fill sth. in
    wire LHU = Lop & funct3_5;                            //to fill sth. in

    wire SB = Sop & funct3_0;                             //to fill sth. in
    wire SH = Sop & funct3_1;                             //to fill sth. in
    wire SW = Sop & funct3_2;                             //to fill sth. in

    wire LUI   = LUIop;                          //to fill sth. in
    wire AUIPC = AUPICop;                          //to fill sth. in

    wire JAL  = JALop;                           //to fill sth. in
    assign JALR = JALRop & funct3_0;
```
+ detection for JAL, JALR, AUPIC and LUI
``` Verilog

```
+ branch signal
> the operation which need jump and compare
``` Verilog
assign Branch = (B_valid & cmp_res) | JAL | JALR;
```
+ ALU source detection
```Verilog
assign ALUSrc_A = JAL | JALR | AUIPC; 
assign ALUSrc_B = I_valid | L_valid | S_valid | LUI | AUIPC; 
```
+ register used detection signal
```Verilog
assign rs1use = JALR | R_valid | I_valid | S_valid | B_valid | L_valid;                 assign rs2use = S_valid | R_valid | B_valid;
```
+ Hazard detection input signal
``` Verilog
assign hazard_optype =
        {2{R_valid | I_valid | JAL | JALR | LUI | AUIPC} & 2'b01} |
        {2{L_valid} & 2'b10} |
        {2{S_valid} & 2'b11} |
        2'b00;
```

2. **HazardDetectionUnit**
+ stall 
``` Verilog
wire stall = (hazard_optype_ID != 2'b11) & //ID hazard not store
        (hazard_optype_EX == 2'b10) & //EXE hazard load
        (((rd_EXE == rs1_ID) & rs1use_ID) | ((rd_EXE == rs2_ID) & rs2use_ID)); 
        //EXE write to the same reg
```
+ Mem to EX forward
```Verilog

```
+ EX to EX forward
```Verilog

```
+ LS forward
> Load operation to store operation
``` Verilog
wire rs1_forward_LS = (hazard_optype_MEM == 2'b10) & //MEM hazard load
        (rd_MEM == rs1_ID & rd_MEM) & //MEM write to rs1
        (rs1use_ID); //ID read from rs1

wire rs2_forward_LS = (hazard_optype_MEM == 2'b10) & //MEM hazard load
        (rd_MEM == rs2_ID & rd_MEM) & //MEM write to rs2
        (rs2use_ID); //ID read from rs2
```

3. **cmp_32**
+ 此模块用于Branch的ID阶段的判断，传入比较种类和两个寄存器的值，如果比较结果正确，返回1，否则返回0.

``` Verilog

```
