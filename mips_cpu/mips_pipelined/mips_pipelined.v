`timescale 1ns/1ps

// =================================================================
// mips_pipelined.v
//
// 5-stage pipelined MIPS32 processor
//
// Pipeline:
//
//       IF -> ID -> EX -> MEM -> WB
//
// Branch / jump resolution:
//       EX stage
//
// Hazards:
//       - EX/MEM and MEM/WB forwarding
//       - Load-use stall
//       - Taken branch/jump flushes IF/ID and ID/EX
// =================================================================

module mips_pipelined #(
    parameter PROGRAM_FILE = "program_all_isa.hex"
)(

    input wire clk,
    input wire reset

);

    // =============================================================
    // IF STAGE
    // =============================================================

    wire [31:0] pc_current;
    wire [31:0] pc_plus4_if;
    wire [31:0] instr_if;

    wire [31:0] pc_next_candidate;
    wire [31:0] pc_next_final;


    program_counter u_program_counter (

        .clk        (clk),
        .reset      (reset),
        .initial_pc (32'h00000000),
        .next_pc    (pc_next_final),
        .pc         (pc_current)

    );


    pc_plus_4 u_pc_plus_4 (

        .pc        (pc_current),
        .pc_plus_4 (pc_plus4_if)

    );


   instruction_memory #(
        .MEMORY_SIZE (4096),
        .PROGRAM_FILE(PROGRAM_FILE)
    ) u_instruction_memory (

        .address     (pc_current),
        .instruction (instr_if)

    );


    // =============================================================
    // IF / ID REGISTER
    // =============================================================

    wire [31:0] if_id_instruction;
    wire [31:0] if_id_pc_plus4;

    wire if_id_write_enable;
    wire if_id_flush;


    if_id_register u_if_id_register (

        .clk             (clk),
        .reset           (reset),

        .write_enable    (if_id_write_enable),
        .flush           (if_id_flush),

        .instruction_in  (instr_if),
        .pc_plus_4_in    (pc_plus4_if),

        .instruction_out (if_id_instruction),
        .pc_plus_4_out   (if_id_pc_plus4)

    );


    // =============================================================
    // ID STAGE
    // =============================================================

    // -------------------------------------------------------------
    // Instruction fields
    // -------------------------------------------------------------

    wire [5:0]  id_opcode;
    wire [4:0]  id_rs;
    wire [4:0]  id_rt;
    wire [4:0]  id_rd;
    wire [4:0]  id_shamt;
    wire [5:0]  id_funct;
    wire [25:0] id_jump_index;


    assign id_opcode     = if_id_instruction[31:26];
    assign id_rs         = if_id_instruction[25:21];
    assign id_rt         = if_id_instruction[20:16];
    assign id_rd         = if_id_instruction[15:11];
    assign id_shamt      = if_id_instruction[10:6];
    assign id_funct      = if_id_instruction[5:0];
    assign id_jump_index = if_id_instruction[25:0];


    // -------------------------------------------------------------
    // Control Unit
    // -------------------------------------------------------------

    wire       id_reg_write;
    wire [1:0] id_reg_dst;
    wire       id_alu_src;
    wire [2:0] id_alu_control;

    wire       id_mem_read;
    wire       id_mem_write;

    wire       id_branch_eq;
    wire       id_branch_ne;

    wire       id_jump;
    wire       id_jump_reg;

    wire       id_reg_mem_to_reg;
    wire       id_jump_link;

    wire       id_sign_extend;


    pipelined_control_unit u_control_unit (

        .opcode       (id_opcode),
        .funct        (id_funct),

        .reg_dst      (id_reg_dst),
        .alu_src      (id_alu_src),
        .alu_control  (id_alu_control),

        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),

        .branch_eq    (id_branch_eq),
        .branch_ne    (id_branch_ne),

        .jump         (id_jump),
        .jump_reg     (id_jump_reg),

        .reg_write    (id_reg_write),
        .mem_to_reg   (id_reg_mem_to_reg),
        .jump_link    (id_jump_link),

        .sign_extend  (id_sign_extend)

    );


    // =============================================================
    // REGISTER FILE
    // =============================================================

    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;


    // WB signals
    wire       wb_reg_write;
    wire [4:0] wb_dest_reg;
    wire [31:0] wb_write_data;


    reg_file u_reg_file (

        .clk          (clk),
        .reset        (reset),

        .read_addr1   (id_rs),
        .read_data1   (id_read_data1),

        .read_addr2   (id_rt),
        .read_data2   (id_read_data2),

        .write_enable (wb_reg_write),
        .write_addr   (wb_dest_reg),
        .write_data   (wb_write_data)

    );


    // =============================================================
    // IMMEDIATE GENERATOR
    // =============================================================

    wire [31:0] id_immediate;


    immediate_generator u_immediate_generator (

        .instruction (if_id_instruction),
        .sign_extend (id_sign_extend),
        .immediate   (id_immediate)

    );


    // =============================================================
    // HAZARD DETECTION
    // =============================================================

    wire       hz_pc_write;
    wire       hz_if_id_write;
    wire       hz_control_flush;


    // These are generated by ID/EX register below.
    wire idex_mem_read;
    wire idex_mem_write;
    wire [4:0] idex_rt;


    hazard_detection_unit u_hazard_detection_unit (

        .id_ex_mem_read (idex_mem_read),
        .id_ex_rt       (idex_rt),

        .if_id_opcode   (id_opcode),
        .if_id_funct    (id_funct),

        .if_id_rs       (id_rs),
        .if_id_rt       (id_rt),

        .pc_write       (hz_pc_write),
        .if_id_write    (hz_if_id_write),
        .control_flush  (hz_control_flush)

    );


    // =============================================================
    // ID / EX REGISTER
    // =============================================================

    wire [31:0] idex_pc;
    wire [31:0] idex_pc_plus4;

    wire [31:0] idex_read_data1;
    wire [31:0] idex_read_data2;

    wire [31:0] idex_immediate;

    wire [4:0] idex_rs;
    wire [4:0] idex_rd;

    wire [4:0] idex_shamt;

    wire [25:0] idex_jump_index;


    // WB control
    wire       idex_reg_write;
    wire       idex_mem_to_reg;
    wire       idex_jump_link;
    wire [1:0] idex_reg_dst;


    // EX control
    wire       idex_alu_src;
    wire [2:0] idex_alu_control;

    wire idex_branch_eq;
    wire idex_branch_ne;

    wire idex_jump;
    wire idex_jump_reg;


    // -------------------------------------------------------------
    // Control-transfer flush from EX
    // -------------------------------------------------------------

    wire ex_control_transfer_taken;


    // Load-use hazard inserts a bubble into ID/EX.
    //
    // A taken branch/jump also flushes the instruction currently
    // sitting in ID before it can enter EX.
    //
    wire idex_flush;
    assign idex_flush =
        hz_control_flush |
        ex_control_transfer_taken;


   


    id_ex_register u_id_ex_register (

        .clk        (clk),
        .reset      (reset),
        .flush      (idex_flush),

        // ---------------------------------------------------------
        // Datapath
        // ---------------------------------------------------------

        .pc_in            (if_id_pc_plus4 - 32'd4),
        .pc_plus_4_in     (if_id_pc_plus4),

        .read_data1_in    (id_read_data1),
        .read_data2_in    (id_read_data2),

        .immediate_in     (id_immediate),

        .rs_in            (id_rs),
        .rt_in            (id_rt),
        .rd_in            (id_rd),

        .shamt_in         (id_shamt),

        .jump_index_in    (id_jump_index),

        // ---------------------------------------------------------
        // WB
        // ---------------------------------------------------------

        .reg_write_in     (id_reg_write),
        .mem_to_reg_in    (id_reg_mem_to_reg),
        .jump_link_in     (id_jump_link),
        .reg_dst_in       (id_reg_dst),

        // ---------------------------------------------------------
        // MEM
        // ---------------------------------------------------------

        .mem_read_in      (id_mem_read),
        .mem_write_in     (id_mem_write),

        // ---------------------------------------------------------
        // EX
        // ---------------------------------------------------------

        .alu_src_in       (id_alu_src),
        .alu_control_in   (id_alu_control),

        .branch_eq_in     (id_branch_eq),
        .branch_ne_in     (id_branch_ne),

        .jump_in          (id_jump),
        .jump_reg_in      (id_jump_reg),

        // ---------------------------------------------------------
        // Outputs
        // ---------------------------------------------------------

        .pc_out            (idex_pc),
        .pc_plus_4_out     (idex_pc_plus4),

        .read_data1_out    (idex_read_data1),
        .read_data2_out    (idex_read_data2),

        .immediate_out     (idex_immediate),

        .rs_out            (idex_rs),
        .rt_out            (idex_rt),
        .rd_out            (idex_rd),

        .shamt_out         (idex_shamt),

        .jump_index_out    (idex_jump_index),

        .reg_write_out     (idex_reg_write),
        .mem_to_reg_out    (idex_mem_to_reg),
        .jump_link_out     (idex_jump_link),
        .reg_dst_out       (idex_reg_dst),

        .mem_read_out      (idex_mem_read),
        .mem_write_out     (idex_mem_write),

        .alu_src_out       (idex_alu_src),
        .alu_control_out   (idex_alu_control),

        .branch_eq_out     (idex_branch_eq),
        .branch_ne_out     (idex_branch_ne),

        .jump_out          (idex_jump),
        .jump_reg_out      (idex_jump_reg)

    );


    // =============================================================
    // EX STAGE
    // =============================================================

    // -------------------------------------------------------------
    // EX/MEM forwarding signals
    // -------------------------------------------------------------

    wire       exmem_reg_write;
    wire [4:0] exmem_dest_reg;
    wire [31:0] exmem_alu_result;


    // -------------------------------------------------------------
    // MEM/WB forwarding signals
    // -------------------------------------------------------------

    wire       memwb_reg_write;
    wire [4:0] memwb_dest_reg;


    // -------------------------------------------------------------
    // Forwarding Unit
    // -------------------------------------------------------------

    wire [1:0] ex_forwardA;
    wire [1:0] ex_forwardB;


    forwarding_unit u_forwarding_unit (

        .id_ex_rs         (idex_rs),
        .id_ex_rt         (idex_rt),

        .ex_mem_reg_write (exmem_reg_write),
        .ex_mem_rd        (exmem_dest_reg),

        .mem_wb_reg_write (memwb_reg_write),
        .mem_wb_rd        (memwb_dest_reg),

        .forwardA         (ex_forwardA),
        .forwardB         (ex_forwardB)

    );


    // -------------------------------------------------------------
    // Forwarded operand A
    // -------------------------------------------------------------

    wire [31:0] ex_forwardA_data;


    forward_mux u_forward_mux_a (

        .normal_data (idex_read_data1),
        .ex_mem_data (exmem_alu_result),
        .mem_wb_data (wb_write_data),

        .forward_sel (ex_forwardA),

        .out_data    (ex_forwardA_data)

    );


    // -------------------------------------------------------------
    // Forwarded operand B
    // -------------------------------------------------------------

    wire [31:0] ex_forwardB_data;


    forward_mux u_forward_mux_b (

        .normal_data (idex_read_data2),
        .ex_mem_data (exmem_alu_result),
        .mem_wb_data (wb_write_data),

        .forward_sel (ex_forwardB),

        .out_data    (ex_forwardB_data)

    );


    // -------------------------------------------------------------
    // ALU operand B
    // -------------------------------------------------------------

    wire [31:0] ex_alu_operand_b;


    assign ex_alu_operand_b =
        idex_alu_src ?
        idex_immediate :
        ex_forwardB_data;


    // -------------------------------------------------------------
    // Destination register
    // -------------------------------------------------------------

    wire [4:0] ex_dest_reg;


    assign ex_dest_reg =
        (idex_reg_dst == 2'b01) ? idex_rd :
        (idex_reg_dst == 2'b10) ? 5'd31 :
                                  idex_rt;


    // -------------------------------------------------------------
    // ALU
    // -------------------------------------------------------------

    wire [31:0] ex_alu_result;
    wire        ex_alu_zero;


    alu u_alu (

        .operand_a   (ex_forwardA_data),
        .operand_b   (ex_alu_operand_b),
        .shamt       (idex_shamt),
        .alu_control (idex_alu_control),

        .result      (ex_alu_result),
        .zero        (ex_alu_zero)

    );


    // =============================================================
    // EX-STAGE CONTROL TRANSFER LOGIC
    // =============================================================

    // -------------------------------------------------------------
    // Branch comparison
    //
    // IMPORTANT:
    // Use forwarded operands, not raw ID/EX register values.
    // -------------------------------------------------------------

    wire ex_branch_equal;


    assign ex_branch_equal =
        (ex_forwardA_data == ex_forwardB_data);


    // -------------------------------------------------------------
    // Branch taken
    // -------------------------------------------------------------

    wire ex_branch_taken;


    assign ex_branch_taken =
        (idex_branch_eq &&  ex_branch_equal) ||
        (idex_branch_ne && !ex_branch_equal);


    // -------------------------------------------------------------
    // Branch target
    //
    // PC + 4 + (sign_extended_offset << 2)
    // -------------------------------------------------------------

    wire [31:0] ex_branch_target;


    assign ex_branch_target =
        idex_pc_plus4 +
        (idex_immediate << 2);


    // -------------------------------------------------------------
    // Jump target
    //
    // {PC+4[31:28], instruction[25:0], 2'b00}
    // -------------------------------------------------------------

    wire [31:0] ex_jump_target;


    assign ex_jump_target =
        {
            idex_pc_plus4[31:28],
            idex_jump_index,
            2'b00
        };


    // -------------------------------------------------------------
    // JR target
    //
    // Forwarded rs value.
    // -------------------------------------------------------------

    wire [31:0] ex_register_target;


    assign ex_register_target =
        ex_forwardA_data;


    // -------------------------------------------------------------
    // Overall EX control transfer
    // -------------------------------------------------------------

    assign ex_control_transfer_taken =
        ex_branch_taken |
        idex_jump |
        idex_jump_reg;


    // =============================================================
    // NEXT PC
    // =============================================================

    next_pc u_next_pc (

        .pc_plus_4       (pc_plus4_if),

        .branch_target   (ex_branch_target),
        .jump_target     (ex_jump_target),
        .register_target (ex_register_target),

        .branch_taken    (ex_branch_taken),

        .jump            (idex_jump),
        .jump_reg        (idex_jump_reg),

        .next_pc         (pc_next_candidate)

    );


    // =============================================================
    // PC / IF-ID CONTROL
    // =============================================================

    // During a load-use hazard:
    //
    //     PC     = HOLD
    //     IF/ID  = HOLD
    //     ID/EX  = BUBBLE
    //
    // During a taken branch/jump:
    //
    //     PC     = TARGET
    //     IF/ID  = FLUSH
    //     ID/EX  = FLUSH
    //
    // The EX control-transfer signal is combinationally generated
    // from the instruction currently in EX.
    // =============================================================


    assign pc_next_final =
        hz_pc_write ?
        pc_next_candidate :
        pc_current;


    assign if_id_write_enable =
        hz_if_id_write;


    assign if_id_flush =
        ex_control_transfer_taken;


    // =============================================================
    // EX / MEM REGISTER
    // =============================================================

    wire [31:0] exmem_write_data;
    wire [31:0] exmem_pc_plus4;

    wire exmem_mem_to_reg;
    wire exmem_jump_link;

    wire exmem_mem_read;
    wire exmem_mem_write;


    ex_mem_register u_ex_mem_register (

        .clk                 (clk),
        .reset               (reset),

        .alu_result_in       (ex_alu_result),
        .write_data_in       (ex_forwardB_data),
        .pc_plus_4_in        (idex_pc_plus4),

        .destination_reg_in  (ex_dest_reg),

        .reg_write_in        (idex_reg_write),
        .mem_to_reg_in       (idex_mem_to_reg),
        .jump_link_in        (idex_jump_link),

        .mem_read_in         (idex_mem_read),
        .mem_write_in        (idex_mem_write),

        .alu_result_out      (exmem_alu_result),
        .write_data_out      (exmem_write_data),
        .pc_plus_4_out       (exmem_pc_plus4),

        .destination_reg_out (exmem_dest_reg),

        .reg_write_out       (exmem_reg_write),
        .mem_to_reg_out      (exmem_mem_to_reg),
        .jump_link_out       (exmem_jump_link),

        .mem_read_out        (exmem_mem_read),
        .mem_write_out       (exmem_mem_write)

    );


    // =============================================================
    // MEM STAGE
    // =============================================================

    wire [31:0] mem_read_data;


    data_memory u_data_memory (

        .clk        (clk),
        .address    (exmem_alu_result),
        .write_data (exmem_write_data),

        .mem_read   (exmem_mem_read),
        .mem_write  (exmem_mem_write),

        .read_data  (mem_read_data)

    );


    // =============================================================
    // MEM / WB REGISTER
    // =============================================================

    wire [31:0] memwb_memory_data;
    wire [31:0] memwb_alu_result;
    wire [31:0] memwb_pc_plus4;

    wire memwb_mem_to_reg;
    wire memwb_jump_link;


    mem_wb_register u_mem_wb_register (

        .clk                 (clk),
        .reset               (reset),

        .memory_data_in      (mem_read_data),
        .alu_result_in       (exmem_alu_result),
        .pc_plus_4_in        (exmem_pc_plus4),

        .destination_reg_in  (exmem_dest_reg),

        .reg_write_in        (exmem_reg_write),
        .mem_to_reg_in       (exmem_mem_to_reg),
        .jump_link_in        (exmem_jump_link),

        .memory_data_out     (memwb_memory_data),
        .alu_result_out      (memwb_alu_result),
        .pc_plus_4_out       (memwb_pc_plus4),

        .destination_reg_out (memwb_dest_reg),

        .reg_write_out       (memwb_reg_write),
        .mem_to_reg_out      (memwb_mem_to_reg),
        .jump_link_out       (memwb_jump_link)

    );


    // =============================================================
    // WB STAGE
    // =============================================================

    writeback_mux u_writeback_mux (

        .alu_result  (memwb_alu_result),
        .memory_data (memwb_memory_data),
        .pc_plus_4   (memwb_pc_plus4),

        .mem_to_reg  (memwb_mem_to_reg),
        .jump_link   (memwb_jump_link),

        .write_data  (wb_write_data)

    );


    // =============================================================
    // REGISTER FILE WRITEBACK
    // =============================================================

    assign wb_reg_write = memwb_reg_write;

    assign wb_dest_reg = memwb_dest_reg;


endmodule