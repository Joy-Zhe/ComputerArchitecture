// function unit
`define FU_BLANK    3'd0
`define FU_ALU      3'd1
`define FU_MEM      3'd2
`define FU_MUL      3'd3
`define FU_DIV      3'd4
`define FU_JUMP     3'd5

// immediate types
`define Imm_type_I 3'b001
`define Imm_type_B 3'b010
`define Imm_type_J 3'b011
`define Imm_type_S 3'b100
`define Imm_type_U 3'b101

`define Q_NULL 0
`define RRS_NULL 0
//‰ªéRS[1]Âº?Âßã‰æùÊ¨?
`define none 4'd0
`define add1 4'd1
`define add2 4'd2
`define add3 4'd3
`define mul1 4'd4
`define mul2 4'd5
`define div1 4'd6
`define mem1 4'd7
`define mem2 4'd8
`define brh1 4'd9

// bits in FUS
`define BUSY    0       // [1]
`define OP_L    1       // [5:1]
`define OP_H    5
`define VJ_L   6       // [10:6]
`define VJ_H   37
`define VK_L  38      // [15:11]
`define VK_H  69
`define QJ_L  70      // [20:16]
`define QJ_H  73
`define QK_L  74
`define QK_H  77
`define IMM_L   78      // [23:21]
`define IMM_H   109
`define PC_L   110      // [26:24]
`define PC_H   141
`define RD_L    142      // [27]
`define RD_H    146      // [28]


// op in FUS
`define ALU_ADD     5'b0_0001
`define ALU_SUB     5'b0_0010
`define ALU_AND     5'b0_0011
`define ALU_OR      5'b0_0100
`define ALU_XOR     5'b0_0101
`define ALU_SLL     5'b0_0110
`define ALU_SRL     5'b0_0111
`define ALU_SLT     5'b0_1000
`define ALU_SLTU    5'b0_1001
`define ALU_SRA     5'b0_1010

`define ALU_ADDI    5'b1_0001
`define ALU_ANDI    5'b1_0011
`define ALU_ORI     5'b1_0100
`define ALU_XORI    5'b1_0101
`define ALU_SLLI    5'b1_0110
`define ALU_SRLI    5'b1_0111
`define ALU_SLTI    5'b1_1000
`define ALU_SLTIU   5'b1_1001
`define ALU_SRAI    5'b1_1010
`define ALU_AUIPC   5'b1_1011   // ALU ctrl use 0001 (ADDI)
`define ALU_LUI     5'b1_1100


// 0; bhw; write enable
`define MEM_LB      5'b0_000_0
`define MEM_LH      5'b0_001_0
`define MEM_LW      5'b0_010_0
`define MEM_LBU     5'b0_100_0
`define MEM_LHU     5'b0_101_0
`define MEM_SB      5'b0_000_1
`define MEM_SH      5'b0_001_1
`define MEM_SW      5'b0_010_1

// 00; signed(0) or unsigned(1) for rs1 and rs2; is higher part
`define MUL_MUL     5'b00_00_0
`define MUL_MULH    5'b00_00_1
`define MUL_MULHU   5'b00_11_1
`define MUL_MULHSU  5'b00_01_1

// 000; is REM; is unsigned
`define DIV_DIV     5'b000_00
`define DIV_DIVU    5'b000_01
`define DIV_REM     5'b000_10
`define DIV_REMU    5'b000_11

// 0; cmp ctrl in cmp_32; 0 stands for branch
`define JUMP_BEQ    5'b0_001_0
`define JUMP_BNE    5'b0_010_0
`define JUMP_BLT    5'b0_011_0
`define JUMP_BGE    5'b0_100_0
`define JUMP_BLTU   5'b0_101_0
`define JUMP_BGEU   5'b0_110_0
// is jalr; 000;  1 stands for unconditional jump
`define JUMP_JAL    5'b0_000_1
`define JUMP_JALR   5'b1_000_1