module pipeline_cpu (
    input  logic clk,
    input  logic rst,
    input  logic pipeline,

    wishbone_interface.master fetch_bus,
    wishbone_interface.master wb,

    input  logic external_interrupt,
    input  logic timer_interrupt,
    output logic [31:0] ex_mem_alu_result,
    output logic        alu_valid,
    output logic        done

);

    import pipeline_status::*;
    import forwarding::*;

    logic [31:0] if_id_instr, if_id_pc;
    logic [31:0] id_ex_rs1, id_ex_rs2, id_ex_pc, id_ex_instr;
    logic [4:0]  id_ex_rd;
    logic        id_ex_rd_valid;
    logic [31:0] ex_mem_src, ex_mem_rd_data, ex_mem_pc, ex_mem_npc, ex_mem_instr;
    logic [4:0]  ex_mem_rd;
    logic        ex_mem_rd_valid;
    logic [31:0] mem_wb_src, mem_wb_rd_data, mem_wb_pc, mem_wb_npc, mem_wb_instr;
    logic [4:0]  mem_wb_rd;
    logic        mem_wb_rd_valid;

    forwarding::t forwarding_exe, forwarding_mem, forwarding_wb;

    pipeline_status::forwards_t status_fwd_fetch, status_fwd_decode, status_fwd_exe, status_fwd_mem;
    pipeline_status::backwards_t status_bwd_fetch, status_bwd_decode, status_bwd_exe, status_bwd_mem, status_bwd_wb;
    logic [31:0] jump_bwd_fetch, jump_bwd_decode, jump_bwd_exe, jump_bwd_mem, jump_bwd_wb;

    logic fetch_valid, decode_valid;
    logic stall;
    logic dump_registers;

    logic [4:0] rs1_addr, rs2_addr;
    logic [31:0] rs1_raw_data, rs2_raw_data;
    logic        stall_out;

    hazard_unit hazard_unit_inst (
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .exe_valid(id_ex_rd_valid),
        .exe_rd(id_ex_rd),
        .mem_valid(ex_mem_rd_valid),
        .mem_rd(ex_mem_rd),
        .wb_valid(mem_wb_rd_valid),
        .wb_rd(mem_wb_rd),
        .stall_in(stall_out),
        .stall(stall)
    );

    register rf (
        .clk(clk),
        .rst(rst),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .rs1_data(rs1_raw_data),
        .rs2_data(rs2_raw_data),
        .rd_write_enable(mem_wb_rd_valid),
        .rd(mem_wb_rd),
        .rd_data(mem_wb_rd_data),
        .dump_all_regs(dump_registers) 
    );

    logic [31:0] fetched_instr, fetched_pc;
    assign status_bwd_fetch = status_bwd_decode;
    assign jump_bwd_fetch   = jump_bwd_decode;
    logic        branch_taken;
    
    logic [31:0] exe_pc, exe_npc;

    fetch_stage fetch_inst (
        .clk(clk),
        .rst(rst),
        .wb(fetch_bus),
        .instruction_reg_out(fetched_instr),
        .program_counter_reg_out(fetched_pc),
        .status_forwards_out(status_fwd_fetch),
        .status_backwards_in(status_bwd_fetch),
        .jump_address_backwards_in(jump_bwd_fetch),
        .stall_pipeline(stall),
        .branch_taken_in(branch_taken),
        .branch_target_pc_in(exe_npc)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            if_id_instr <= 32'd0;
            if_id_pc    <= 32'd0;
            fetch_valid <= 1'b0;
        end else if (!stall) begin
            if_id_instr <= fetched_instr;
            if_id_pc    <= fetched_pc;
            fetch_valid <= (status_fwd_fetch == VALID);
        end
    end

    logic [31:0] rs1_data, rs2_data, decoded_instr;
    logic [4:0]  decoded_rd;
    logic        decoded_rd_valid;
    logic        wb_fwd_valid_reg;
    logic [4:0]  wb_fwd_rd_reg;
    logic [31:0] wb_fwd_data_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_fwd_valid_reg <= 1'b0;
            wb_fwd_rd_reg    <= 5'd0;
            wb_fwd_data_reg  <= 32'd0;
        end else begin
            wb_fwd_valid_reg <= forwarding_wb.data_valid;
            wb_fwd_rd_reg    <= forwarding_wb.address;
            wb_fwd_data_reg  <= forwarding_wb.data;
        end
    end


    decode_stage decode_inst (
        .clk(clk),
        .rst(rst),
        .instruction_in(if_id_instr),
        .program_counter_in(if_id_pc),
        .fetch_valid(fetch_valid),
        .rs1_data_in(rs1_raw_data),
        .rs2_data_in(rs2_raw_data),
        .exe_fwd_valid(forwarding_exe.data_valid),
        .exe_fwd_rd(forwarding_exe.address),
        .exe_fwd_data(forwarding_exe.data),
        .mem_fwd_valid(forwarding_mem.data_valid),
        .mem_fwd_rd(forwarding_mem.address),
        .mem_fwd_data(forwarding_mem.data),
        .wb_fwd_valid(wb_fwd_valid_reg),
        .wb_fwd_rd(wb_fwd_rd_reg),
        .wb_fwd_data(wb_fwd_data_reg),
        .rs1_data_reg_out(rs1_data),
        .rs2_data_reg_out(rs2_data),
        .program_counter_reg_out(),
        .instruction_out(decoded_instr),
        .rd_out(decoded_rd),
        .stall_pipeline(stall),
        .rd_valid_out(decoded_rd_valid),
        .status_forwards_in(status_fwd_fetch),
        .status_forwards_out(status_fwd_decode),
        .status_backwards_in(status_bwd_decode),
        .status_backwards_out(status_bwd_decode),
        .jump_address_backwards_in(jump_bwd_decode),
        .jump_address_backwards_out(jump_bwd_decode),
        .rs1_out(rs1_addr),
        .rs2_out(rs2_addr)
    );

    always_ff @(posedge clk) begin
        if (rst || stall || !fetch_valid) begin
            id_ex_rs1      <= 32'd0;
            id_ex_rs2      <= 32'd0;
            id_ex_instr    <= 32'd0;
            id_ex_rd       <= 5'd0;
            id_ex_rd_valid <= 1'b0;
            id_ex_pc       <= 32'd0;
            decode_valid   <= 1'b0;
        end else begin
            id_ex_rs1      <= rs1_data;
            id_ex_rs2      <= rs2_data;
            id_ex_instr    <= decoded_instr;
            id_ex_rd       <= decoded_rd;
            id_ex_rd_valid <= decoded_rd_valid;
            id_ex_pc       <= if_id_pc;
            decode_valid   <= 1'b1;
        end
    end

    logic [31:0] exe_src, exe_rd_data, exe_instr;
    logic [4:0]  exe_rd;
    logic        exe_rd_valid;
    logic [31:0] alu_result;
    logic        done_out;


    execute_stage execute_inst (
        .clk(clk),
        .rst(rst),
        .rs1_data_in(id_ex_rs1),
        .rs2_data_in(id_ex_rs2),
        .instruction_bits_in(id_ex_instr),
        .rd_in(id_ex_rd),
        .rd_valid_in(id_ex_rd_valid),
        .program_counter_in(id_ex_pc),
        .valid_in(decode_valid),
        .stall_in(1'b0),
        .fwd_valid_in(forwarding_mem.data_valid),
        .fwd_rd_in(forwarding_mem.address),
        .fwd_data_in(forwarding_mem.data),
        .source_data_reg_out(exe_src),
        .rd_data_reg_out(exe_rd_data),
        .instruction_bits_out(exe_instr),
        .rd_out(exe_rd),
        .rd_valid_out(exe_rd_valid),
        .program_counter_reg_out(exe_pc),
        .next_program_counter_reg_out(exe_npc),
        .fwd_valid_out(forwarding_exe.data_valid),
        .fwd_rd_out(forwarding_exe.address),
        .fwd_data_out(forwarding_exe.data),
        .status_forwards_in(status_fwd_decode),
        .status_forwards_out(status_fwd_exe),
        .status_backwards_in(status_bwd_exe),
        .status_backwards_out(status_bwd_exe),
        .jump_address_backwards_in(jump_bwd_exe),
        .jump_address_backwards_out(jump_bwd_exe),
        .computed_result(alu_result),
        .alu_valid(alu_valid),
        .branch_taken(branch_taken),
        .stall_out(stall_out),
        .pipeline(pipeline),
        .done_out(done_out)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            ex_mem_src      <= 32'd0;
            ex_mem_rd_data  <= 32'd0;
            ex_mem_instr    <= 32'd0;
            ex_mem_rd       <= 5'd0;
            ex_mem_rd_valid <= 1'b0;
            ex_mem_pc       <= 32'd0;
            ex_mem_npc      <= 32'd0;
            ex_mem_alu_result <= 32'd0;
        end else begin
            ex_mem_src      <= exe_src;
            ex_mem_rd_data  <= exe_rd_data;
            ex_mem_instr    <= exe_instr;
            ex_mem_rd       <= exe_rd;
            ex_mem_rd_valid <= exe_rd_valid;
            ex_mem_pc       <= exe_pc;
            ex_mem_npc      <= exe_npc;
            ex_mem_alu_result = alu_result; 
        end
    end

    memory_stage memory_inst (
        .clk(clk),
        .rst(rst),
        .wb(wb),
        .source_data_in(ex_mem_src),
        .rd_data_in(ex_mem_rd_data),
        .instruction_bits_in(ex_mem_instr),
        .rd_in(ex_mem_rd),
        .rd_valid_in(ex_mem_rd_valid),
        .program_counter_in(ex_mem_pc),
        .next_program_counter_in(ex_mem_npc),
        .stall_in(1'b0), 
        .source_data_reg_out(mem_wb_src),
        .rd_data_reg_out(mem_wb_rd_data),
        .instruction_bits_out(mem_wb_instr),
        .rd_out(mem_wb_rd),
        .rd_valid_out(mem_wb_rd_valid),
        .program_counter_reg_out(mem_wb_pc),
        .next_program_counter_reg_out(mem_wb_npc),
        .fwd_valid_out(forwarding_mem.data_valid),
        .fwd_rd_out(forwarding_mem.address),
        .fwd_data_out(forwarding_mem.data),
        .status_forwards_in(status_fwd_exe),
        .status_forwards_out(status_fwd_mem),
        .status_backwards_in(status_bwd_mem),
        .status_backwards_out(status_bwd_mem),
        .jump_address_backwards_in(jump_bwd_mem),
        .jump_address_backwards_out(jump_bwd_mem),
        .address_in(ex_mem_alu_result)
    );

    writeback_stage writeback_inst (
        .clk(clk),
        .rst(rst),
        .source_data_in(mem_wb_src),
        .rd_data_in(mem_wb_rd_data),
        .instruction_bits_in(mem_wb_instr),
        .rd_in(mem_wb_rd),
        .rd_valid_in(mem_wb_rd_valid),
        .program_counter_in(mem_wb_pc),
        .next_program_counter_in(mem_wb_npc),
        .external_interrupt_in(external_interrupt),
        .timer_interrupt_in(timer_interrupt),
        .fwd_valid_out(forwarding_wb.data_valid),
        .fwd_rd_out(forwarding_wb.address),
        .fwd_data_out(forwarding_wb.data),
        .dump_all_regs_out(dump_registers),
        .status_forwards_in(status_fwd_mem),
        .status_backwards_out(status_bwd_wb),
        .jump_address_backwards_out(jump_bwd_wb),
        .stall_out(stall_out),
        .done_in(done_out),
        .done_out(done)
    );
    
endmodule
