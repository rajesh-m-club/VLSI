`timescale 1ns/1ps

module mips_single_cycle (

    input wire clk,
    input wire reset

);


    // =========================================================
    // PROGRAM COUNTER
    // =========================================================

    wire [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] next_pc;


    pc_plus_4 pc_adder (

        .pc        (pc),
        .pc_plus_4 (pc_plus_4)

    );


    program_counter pc_unit (

        .clk        (clk),
        .reset      (reset),
        .initial_pc (32'd0),
        .next_pc    (next_pc),
        .pc         (pc)

    );


    // =========================================================
    // INSTRUCTION MEMORY
    // =========================================================

    wire [31:0] instruction;


    instruction_memory #(

        .PROGRAM_FILE("program_all_isa.hex")

    ) instruction_mem (

        .address     (pc),
        .instruction (instruction)

    );


    // =========================================================
    // INSTRUCTION FIELDS
    // =========================================================

    wire [5:0] opcode;
    wire [5:0] funct;

    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [4:0] shamt;


    assign opcode = instruction[31:26];

    assign rs     = instruction[25:21];

    assign rt     = instruction[20:16];

    assign rd     = instruction[15:11];

    assign shamt  = instruction[10:6];

    assign funct  = instruction[5:0];


    // =========================================================
    // CONTROL SIGNALS
    // =========================================================

    wire        reg_write;
    wire [1:0]  reg_dst;

    wire        alu_src;
    wire [2:0]  alu_control;

    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;

    wire        branch_eq;
    wire        branch_ne;

    wire        jump;
    wire        jump_link;
    wire        jump_reg;

    wire        sign_extend;


    // =========================================================
    // CONTROL UNIT
    // =========================================================

    control_unit control (

        .opcode      (opcode),
        .funct       (funct),

        .reg_write   (reg_write),
        .reg_dst     (reg_dst),

        .alu_src     (alu_src),
        .alu_control (alu_control),

        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .mem_to_reg  (mem_to_reg),

        .branch_eq   (branch_eq),
        .branch_ne   (branch_ne),

        .jump        (jump),
        .jump_link   (jump_link),
        .jump_reg    (jump_reg),

        .sign_extend (sign_extend)

    );


    // =========================================================
    // REGISTER FILE
    // =========================================================

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    wire [4:0]  write_addr;

    wire [31:0] write_data;


    assign write_addr =

        (reg_dst == 2'b00) ? rt :

        (reg_dst == 2'b01) ? rd :

        5'd31;


    reg_file registers (

        .clk          (clk),

        .read_addr1   (rs),
        .read_data1   (read_data1),

        .read_addr2   (rt),
        .read_data2   (read_data2),

        .write_enable (reg_write),
        .write_addr   (write_addr),
        .write_data   (write_data)

    );


    // =========================================================
    // IMMEDIATE GENERATOR
    // =========================================================

    wire [31:0] immediate;


    immediate_generator imm_gen (

        .instruction (instruction),
        .sign_extend (sign_extend),
        .immediate   (immediate)

    );


    // =========================================================
    // ALU
    // =========================================================

    wire [31:0] alu_operand_b;

    wire [31:0] alu_result;

    wire        zero;


    assign alu_operand_b =

        alu_src ? immediate :

        read_data2;


    alu alu_unit (

        .operand_a   (read_data1),
        .operand_b   (alu_operand_b),

        .shamt       (shamt),

        .alu_control (alu_control),

        .result      (alu_result),

        .zero        (zero)

    );


    // =========================================================
    // DATA MEMORY
    // =========================================================

    wire [31:0] memory_data;


    data_memory data_mem (

        .clk        (clk),

        .address    (alu_result),

        .write_data (read_data2),

        .mem_read   (mem_read),

        .mem_write  (mem_write),

        .read_data  (memory_data)

    );


    // =========================================================
    // WRITEBACK MUX
    // =========================================================

    writeback_mux writeback (

        .alu_result  (alu_result),

        .memory_data (memory_data),

        .pc_plus_4   (pc_plus_4),

        .mem_to_reg  (mem_to_reg),

        .jump_link   (jump_link),

        .write_data  (write_data)

    );


    // =========================================================
    // BRANCH TARGET
    // =========================================================

    wire [31:0] branch_target;


    branch_target branch_unit (

        .pc_plus_4     (pc_plus_4),

        .branch_offset (immediate),

        .branch_target (branch_target)

    );


    // =========================================================
    // JUMP TARGET
    // =========================================================

    wire [31:0] jump_target;


    jump_target jump_unit (

        .pc_plus_4  (pc_plus_4),

        .jump_index (instruction[25:0]),

        .jump_target(jump_target)

    );


    // =========================================================
    // NEXT PC LOGIC
    // =========================================================

    next_pc next_pc_unit (

        .pc_plus_4      (pc_plus_4),

        .branch_target   (branch_target),

        .jump_target     (jump_target),

        .register_target (read_data1),

        .branch_eq       (branch_eq),

        .branch_ne       (branch_ne),

        .zero            (zero),

        .jump            (jump),

        .jump_reg        (jump_reg),

        .next_pc         (next_pc)

    );


endmodule