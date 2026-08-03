// =================================================================
// mips_pipelined.v
// Top-level module for a 5-stage pipelined MIPS32 processor
// =================================================================
//
// IMPORTANT DESIGN NOTE (please read):
//
// The prose spec says branch/jump comparison+target happen in EX.
// However, `id_ex_register` (as provided) has NO fields for
// branch_eq, branch_ne, jump, or jump_reg -- only reg_write,
// mem_to_reg, jump_link, reg_dst, mem_read, mem_write, alu_src,
// and alu_control survive into ID/EX. That means these four control
// signals physically cannot be pipelined into EX with the modules
// given. To keep every module interface untouched, this top module
// resolves ALL branches and jumps (BEQ/BNE/J/JAL/JR) in the ID
// stage instead:
//
//   - branch_target and jump_target are computed in ID stage from
//     IF/ID.instruction and IF/ID.pc_plus_4.
//   - "zero" for the branch compare is produced with a plain
//     equality check (read_data1 == read_data2) rather than routing
//     through the ALU, since the ALU's internal alu_control encoding
//     for SUBTRACT is not specified in the port list and guessing it
//     would risk silently wrong behavior.
//   - JR's register_target is the ID-stage read_data1 (rs).
//
// Consequence: only IF/ID needs to be flushed on a taken
// branch/jump/JR (single bubble), which matches the "Flush IF/ID;
// Update PC" line in the spec exactly. id_ex_register's flush port
// is reserved solely for the load-use hazard bubble
// (hazard_detection_unit.control_flush), as described in the
// HAZARD DETECTION UNIT section of the spec.
//
// Known limitation from this choice: rs/rt used for a branch or JR
// are read directly from the register file in ID with no
// forwarding into ID (the provided forwarding_unit only forwards
// into EX-stage ALU operands). A branch/JR immediately following an
// instruction that hasn't written back yet can see a stale value.
// No module in the given set supports ID-stage forwarding, so this
// is an inherent limitation of the provided module set, not an
// oversight.
//
// =================================================================

module mips_pipelined (
    input wire clk,
    input wire reset
);

    // =============================================================
    // IF Stage
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
        .pc         (pc_current),
        .pc_plus_4  (pc_plus4_if)
    );

    instruction_memory u_instruction_memory (
        .address     (pc_current),
        .instruction (instr_if)
    );

    // pc_next_final is chosen after ID-stage branch/jump resolution
    // and hazard-unit PC freeze logic further below.

    // =============================================================
    // IF/ID Register
    // =============================================================

    wire [31:0] if_id_instruction;
    wire [31:0] if_id_pc_plus4;

    wire        if_id_write_enable;
    wire        if_id_flush;

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
    // ID Stage
    // =============================================================

    // ---- Instruction field decode ----
    wire [5:0]  id_opcode      = if_id_instruction[31:26];
    wire [4:0]  id_rs          = if_id_instruction[25:21];
    wire [4:0]  id_rt          = if_id_instruction[20:16];
    wire [4:0]  id_rd          = if_id_instruction[15:11];
    wire [4:0]  id_shamt       = if_id_instruction[10:6];
    wire [5:0]  id_funct       = if_id_instruction[5:0];
    wire [25:0] id_jump_index  = if_id_instruction[25:0];

    // ---- Control Unit ----
    wire        id_reg_write;
    wire [1:0]  id_reg_dst;
    wire        id_alu_src;
    wire [2:0]  id_alu_control;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_mem_to_reg;
    wire        id_branch_eq;
    wire        id_branch_ne;
    wire        id_jump;
    wire        id_jump_link;
    wire        id_jump_reg;
    wire        id_sign_extend;

    control_unit u_control_unit (
        .opcode       (id_opcode),
        .funct        (id_funct),
        .reg_write    (id_reg_write),
        .reg_dst      (id_reg_dst),
        .alu_src      (id_alu_src),
        .alu_control  (id_alu_control),
        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),
        .mem_to_reg   (id_mem_to_reg),
        .branch_eq    (id_branch_eq),
        .branch_ne    (id_branch_ne),
        .jump         (id_jump),
        .jump_link    (id_jump_link),
        .jump_reg     (id_jump_reg),
        .sign_extend  (id_sign_extend)
    );

    // ---- Register File ----
    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;

    // Writeback-stage signals (declared later, used here for the
    // register file write port)
    wire        wb_reg_write;
    wire [4:0]  wb_dest_reg;
    wire [31:0] wb_write_data;

    reg_file u_reg_file (
        .clk           (clk),
        .read_addr1    (id_rs),
        .read_data1    (id_read_data1),
        .read_addr2    (id_rt),
        .read_data2    (id_read_data2),
        .write_enable  (wb_reg_write),
        .write_addr    (wb_dest_reg),
        .write_data    (wb_write_data)
    );

    // ---- Immediate Generator ----
    wire [31:0] id_immediate;

    immediate_generator u_immediate_generator (
        .instruction   (if_id_instruction),
        .sign_extend   (id_sign_extend),
        .immediate     (id_immediate)
    );

    // ---- Branch Target Adder (ID stage - see design note above) ----
    wire [31:0] id_branch_target;

    branch_target u_branch_target (
        .pc_plus_4      (if_id_pc_plus4),
        .branch_offset  (id_immediate),
        .branch_target  (id_branch_target)
    );

    // ---- Jump Target Logic (ID stage) ----
    wire [31:0] id_jump_target;

    jump_target u_jump_target (
        .pc_plus_4    (if_id_pc_plus4),
        .jump_index   (id_jump_index),
        .jump_target  (id_jump_target)
    );

    // ---- Branch comparison (plain equality check, see design note) ----
    wire id_zero = (id_read_data1 == id_read_data2);

    // Any of BEQ-taken / BNE-taken / J / JAL / JR triggers a redirect
    // and a single-bubble flush of IF/ID.
    wire id_branch_or_jump_taken =
        (id_branch_eq & id_zero) |
        (id_branch_ne & ~id_zero) |
        id_jump |
        id_jump_reg;

    // ---- Next PC selection logic ----
    next_pc u_next_pc (
        .pc_plus_4       (pc_plus4_if),
        .branch_target   (id_branch_target),
        .jump_target     (id_jump_target),
        .register_target (id_read_data1),   // JR target = rs value
        .branch_eq       (id_branch_eq),
        .branch_ne       (id_branch_ne),
        .zero            (id_zero),
        .jump            (id_jump),
        .jump_reg        (id_jump_reg),
        .next_pc         (pc_next_candidate)
    );

    // =============================================================
    // Hazard Detection Unit
    // =============================================================

    wire hz_pc_write;
    wire hz_if_id_write;
    wire hz_control_flush;

    // ID/EX outputs used by the hazard unit (declared here, driven
    // by the ID/EX register instantiated in the EX Stage section)
    wire        idex_mem_read;
    wire [4:0]  idex_rt;

    hazard_detection_unit u_hazard_detection_unit (
        .id_ex_mem_read (idex_mem_read),
        .id_ex_rt       (idex_rt),
        .if_id_rs       (id_rs),
        .if_id_rt       (id_rt),
        .pc_write       (hz_pc_write),
        .if_id_write    (hz_if_id_write),
        .control_flush  (hz_control_flush)
    );

    // ---- Glue: PC freeze mux (load-use stall holds PC) ----
    assign pc_next_final = hz_pc_write ? pc_next_candidate : pc_current;

    // ---- Glue: IF/ID write-enable / flush wiring ----
    assign if_id_write_enable = hz_if_id_write;
    assign if_id_flush        = id_branch_or_jump_taken;

    // =============================================================
    // ID/EX Register
    // =============================================================

    wire [31:0] idex_pc_plus4;
    wire [31:0] idex_read_data1;
    wire [31:0] idex_read_data2;
    wire [31:0] idex_immediate;
    wire [4:0]  idex_rs;
    wire [4:0]  idex_rd;
    wire [4:0]  idex_shamt;

    wire        idex_reg_write;
    wire        idex_mem_to_reg;
    wire        idex_jump_link;
    wire [1:0]  idex_reg_dst;

    wire        idex_mem_write;

    wire        idex_alu_src;
    wire [2:0]  idex_alu_control;

    // Load-use hazard bubble only (see design note above for why
    // branch/jump do not flush ID/EX in this build).
    wire idex_flush = hz_control_flush;

    id_ex_register u_id_ex_register (
        .clk              (clk),
        .reset            (reset),
        .flush            (idex_flush),

        .pc_plus_4_in     (if_id_pc_plus4),
        .read_data1_in    (id_read_data1),
        .read_data2_in    (id_read_data2),
        .immediate_in     (id_immediate),
        .rs_in            (id_rs),
        .rt_in            (id_rt),
        .rd_in            (id_rd),
        .shamt_in         (id_shamt),

        .reg_write_in     (id_reg_write),
        .mem_to_reg_in    (id_mem_to_reg),
        .jump_link_in     (id_jump_link),
        .reg_dst_in       (id_reg_dst),

        .mem_read_in      (id_mem_read),
        .mem_write_in     (id_mem_write),

        .alu_src_in       (id_alu_src),
        .alu_control_in   (id_alu_control),

        .pc_plus_4_out    (idex_pc_plus4),
        .read_data1_out   (idex_read_data1),
        .read_data2_out   (idex_read_data2),
        .immediate_out    (idex_immediate),
        .rs_out           (idex_rs),
        .rt_out           (idex_rt),
        .rd_out           (idex_rd),
        .shamt_out        (idex_shamt),

        .reg_write_out    (idex_reg_write),
        .mem_to_reg_out   (idex_mem_to_reg),
        .jump_link_out    (idex_jump_link),
        .reg_dst_out      (idex_reg_dst),

        .mem_read_out     (idex_mem_read),
        .mem_write_out    (idex_mem_write),

        .alu_src_out      (idex_alu_src),
        .alu_control_out  (idex_alu_control)
    );

    // =============================================================
    // EX Stage
    // =============================================================

    // EX/MEM and MEM/WB signals used for forwarding (declared here,
    // driven by registers instantiated further below)
    wire        exmem_reg_write;
    wire [4:0]  exmem_dest_reg;
    wire [31:0] exmem_alu_result;

    wire        memwb_reg_write;
    wire [4:0]  memwb_dest_reg;

    // ---- Forwarding Unit ----
    wire [1:0] ex_forwardA;
    wire [1:0] ex_forwardB;

    forwarding_unit u_forwarding_unit (
        .id_ex_rs          (idex_rs),
        .id_ex_rt          (idex_rt),
        .ex_mem_reg_write  (exmem_reg_write),
        .ex_mem_rd         (exmem_dest_reg),
        .mem_wb_reg_write  (memwb_reg_write),
        .mem_wb_rd         (memwb_dest_reg),
        .forwardA          (ex_forwardA),
        .forwardB          (ex_forwardB)
    );

    // ---- Forward Mux A (operand A -> straight into ALU) ----
    wire [31:0] ex_forwardA_data;

    forward_mux u_forward_mux_a (
        .normal_data   (idex_read_data1),
        .ex_mem_data   (exmem_alu_result),
        .mem_wb_data   (wb_write_data),
        .forward_sel   (ex_forwardA),
        .out_data      (ex_forwardA_data)
    );

    // ---- Forward Mux B (operand B -> ALUSrc mux / store data) ----
    wire [31:0] ex_forwardB_data;

    forward_mux u_forward_mux_b (
        .normal_data   (idex_read_data2),
        .ex_mem_data   (exmem_alu_result),
        .mem_wb_data   (wb_write_data),
        .forward_sel   (ex_forwardB),
        .out_data      (ex_forwardB_data)
    );

    // ---- Glue: ALUSrc mux (forwarded reg B vs. immediate) ----
    wire [31:0] ex_alu_operand_b;
    assign ex_alu_operand_b = idex_alu_src ? idex_immediate : ex_forwardB_data;

    // ---- Glue: RegDst mux (00=rt, 01=rd, 10=$31 for JAL) ----
    wire [4:0] ex_dest_reg;
    assign ex_dest_reg = (idex_reg_dst == 2'b01) ? idex_rd :
                          (idex_reg_dst == 2'b10) ? 5'd31  :
                                                     idex_rt;

    // ---- ALU ----
    wire [31:0] ex_alu_result;
    wire        ex_alu_zero; // unused (branch resolved in ID, see note)

    alu u_alu (
        .operand_a    (ex_forwardA_data),
        .operand_b    (ex_alu_operand_b),
        .shamt        (idex_shamt),
        .alu_control  (idex_alu_control),
        .result       (ex_alu_result),
        .zero         (ex_alu_zero)
    );

    // =============================================================
    // EX/MEM Register
    // =============================================================

    wire [31:0] exmem_write_data;
    wire [31:0] exmem_pc_plus4;

    wire        exmem_mem_to_reg;
    wire        exmem_jump_link;
    wire        exmem_mem_read;
    wire        exmem_mem_write;

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
    // MEM Stage
    // =============================================================

    wire [31:0] mem_read_data;

    data_memory u_data_memory (
        .clk         (clk),
        .address     (exmem_alu_result),
        .write_data  (exmem_write_data),
        .mem_read    (exmem_mem_read),
        .mem_write   (exmem_mem_write),
        .read_data   (mem_read_data)
    );

    // =============================================================
    // MEM/WB Register
    // =============================================================

    wire [31:0] memwb_memory_data;
    wire [31:0] memwb_alu_result;
    wire [31:0] memwb_pc_plus4;

    wire        memwb_mem_to_reg;
    wire        memwb_jump_link;

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
    // WB Stage
    // =============================================================

    writeback_mux u_writeback_mux (
        .alu_result   (memwb_alu_result),
        .memory_data  (memwb_memory_data),
        .pc_plus_4    (memwb_pc_plus4),
        .mem_to_reg   (memwb_mem_to_reg),
        .jump_link    (memwb_jump_link),
        .write_data   (wb_write_data)
    );

    // ---- Glue: register file write-back source signals ----
    assign wb_reg_write = memwb_reg_write;
    assign wb_dest_reg  = memwb_dest_reg;
    // wb_write_data driven by u_writeback_mux above; also reused as
    // the MEM/WB forwarding source in the EX-stage forward muxes.

endmodule