module execute_stage (
    input  logic clk,
    input  logic rst,

    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] instruction_bits_in,
    input  logic [4:0]  rd_in,
    input  logic        rd_valid_in,
    input  logic [31:0] program_counter_in,

    input  logic        fwd_valid_in,
    input  logic [4:0]  fwd_rd_in,
    input  logic [31:0] fwd_data_in,

    input  logic        valid_in,
    input  logic        stall_in,
    input  logic        pipeline,

    output logic [31:0] source_data_reg_out,
    output logic [31:0] rd_data_reg_out,
    output logic [31:0] instruction_bits_out,
    output logic [4:0]  rd_out,
    output logic        rd_valid_out,
    output logic [31:0] program_counter_reg_out,
    output logic [31:0] next_program_counter_reg_out,

    output logic        fwd_valid_out,
    output logic [4:0]  fwd_rd_out,
    output logic [31:0] fwd_data_out,

    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out,
    output logic [31:0] computed_result,
    output logic        alu_valid,
    output logic        branch_taken,
    output logic        stall_out,
    output logic        done_out
);

    import pipeline_status::*;

    logic [31:0] alu_result;
    logic [31:0] instr_reg, pc_reg, rs1_data_reg, rs2_data_reg, imm;
    logic [4:0]  rd_reg;
    logic        valid_reg, rd_valid_reg;
    logic [31:0] completed_instr_reg [0:50];
    logic [31:0] instruction_temp;
    logic [31:0] completed_reg [0:50];
    logic [31:0] completed;
    logic inference_done_d;
    logic inference_done_pulse;
    logic inference_triggered;

    logic [31:0] imm_tmp;
    always_comb begin
        instruction_temp = instruction_bits_in;
        case (instruction_bits_in[6:0])
            7'b0010011, 7'b0000011, 7'b1100111:
                imm_tmp = {{20{instruction_bits_in[31]}}, instruction_bits_in[31:20]};
            7'b0100011:
                imm_tmp = {{20{instruction_bits_in[31]}}, instruction_bits_in[31:25], instruction_bits_in[11:7]};
            7'b1100011:
                imm_tmp = {{19{instruction_bits_in[31]}}, instruction_bits_in[31], instruction_bits_in[7],
                           instruction_bits_in[30:25], instruction_bits_in[11:8], 1'b0};
            7'b0110111, 7'b0010111:
                imm_tmp = {instruction_bits_in[31:12], 12'b0};
            7'b1101111:
                imm_tmp = {{11{instruction_bits_in[31]}}, instruction_bits_in[31], instruction_bits_in[19:12],
                           instruction_bits_in[20], instruction_bits_in[30:21], 1'b0};
            default:
                imm_tmp = 32'b0;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_reg    <= 0;
            pc_reg       <= 0;
            rs1_data_reg <= 0;
            rs2_data_reg <= 0;
            rd_reg       <= 0;
            valid_reg    <= 0;
            rd_valid_reg <= 0;
            imm          <= 0;
        end else if (!stall_in) begin
            instr_reg    <= instruction_bits_in;
            pc_reg       <= program_counter_in;
            rs1_data_reg <= rs1_data_in;
            rs2_data_reg <= rs2_data_in;
            rd_reg       <= rd_in;
            valid_reg    <= valid_in;
            rd_valid_reg <= rd_valid_in;
            imm          <= imm_tmp;
            completed_instr_reg[program_counter_in/4] <=instruction_temp;
 //           $display("LAST",instruction_temp,program_counter_in/4);
        end
    end

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [4:0] rs1_id, rs2_id;

    assign opcode = instr_reg[6:0];
    assign funct3 = instr_reg[14:12];
    assign rs1_id = instr_reg[19:15];
    assign rs2_id = instr_reg[24:20];            

    logic [31:0] rs1_final, rs2_final;
    always_comb begin
        rs1_final = rs1_data_reg;
        rs2_final = rs2_data_reg;
        if (fwd_valid_in && fwd_rd_in != 0) begin
            if (fwd_rd_in == rs1_id) rs1_final = fwd_data_in;
            if (fwd_rd_in == rs2_id) rs2_final = fwd_data_in;
        end
    end

    logic is_cnn_instruction;
    assign is_cnn_instruction = (opcode == 7'b1111110 || opcode == 7'b1111111);

    logic [3:0]  axi_awaddr, axi_araddr;
    logic        axi_awvalid, axi_arvalid, axi_wvalid;
    logic [31:0] axi_wdata,axi_rdata;
    logic        axi_rvalid;
    logic [3:0]  predicted_class;
    logic        inference_done;
    logic displayed_cnn_msg;
    logic cnn_reset;
    logic was_cnn_instruction;

    CNN_Privacy_Module u_cnn (
        .clk(clk),
        .resetn(!rst && !cnn_reset),
        .pipeline(pipeline),
        .axi_awaddr(axi_awaddr),
        .axi_awvalid(axi_awvalid),
        .axi_wdata(axi_wdata),
        .axi_wvalid(axi_wvalid),
        .axi_araddr(axi_araddr),
        .axi_arvalid(axi_arvalid),
        .axi_rdata(axi_rdata),
        .axi_rvalid(axi_rvalid),
        .predicted_class_out(predicted_class),
        .inference_done(inference_done)
    );
 
    wire [31:0] cnn_result;
    wire        cnn_ready;

    typedef enum logic [1:0] {
        CNN_IDLE,
        CNN_TRIGGER,
        CNN_WAIT,
        CNN_DONE
    } cnn_state_t;
    
    cnn_state_t cnn_state;
    logic       cnn_active;
    logic [3:0] predicted_class_reg;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst||cnn_reset) begin
            cnn_state            <= CNN_IDLE;
            displayed_cnn_msg <= 1'b0;
            predicted_class_reg  <= 4'd0;
            inference_triggered  <= 1'b0;
        end else begin
            case (cnn_state)
                CNN_IDLE: begin
                    if (valid_reg && is_cnn_instruction) begin
                        cnn_state           <= CNN_TRIGGER;
                        inference_triggered <= 1'b1;
                    end
                end
    
                CNN_TRIGGER: begin
                    cnn_state <= CNN_WAIT;
                end
    
                CNN_WAIT: begin
                    if (inference_done && inference_triggered) begin
                        cnn_state <= CNN_DONE;
                        inference_triggered <= 1'b0;
                        displayed_cnn_msg <= 1'b0;
                    end
                end
    
                CNN_DONE: begin
//                    $display("DONE",predicted_class);
                    predicted_class_reg <= predicted_class;
                    was_cnn_instruction <= 1;
                    cnn_state <= CNN_DONE;
                end
            endcase
        end
    end


    assign stall_out = (cnn_state == CNN_WAIT);
    
    always_comb begin
        if (is_cnn_instruction) begin
        axi_awaddr  = 4'h0;
        axi_araddr  = 4'hF;
        axi_awvalid = 1;
        axi_wvalid  = 1;
        axi_arvalid = 0;
        axi_wdata = {11'b0,
                instr_reg[19:15],
                opcode == 7'b1111111,
                instr_reg[27:24],
                instr_reg[23:20],
                instr_reg[14:13],
                instr_reg[12],
                instr_reg[31:28]
            };
        end
    end
    
    assign cnn_ready  = (cnn_state == CNN_DONE);
    
    always_comb begin
        alu_result = 32'd0;
        case (opcode)
            7'b0110011: begin
                unique case (funct3)
                    3'b000: alu_result = (instr_reg[31:25] == 7'b0100000) ? rs1_final - rs2_final : rs1_final + rs2_final;
                    3'b001: alu_result = rs1_final << rs2_final[4:0];
                    3'b010: alu_result = ($signed(rs1_final) < $signed(rs2_final)) ? 32'd1 : 32'd0;
                    3'b011: alu_result = (rs1_final < rs2_final) ? 32'd1 : 32'd0;
                    3'b100: alu_result = rs1_final ^ rs2_final;
                    3'b101: alu_result = (instr_reg[31:25] == 7'b0100000) ? $signed(rs1_final) >>> rs2_final[4:0] : rs1_final >> rs2_final[4:0];
                    3'b110: alu_result = rs1_final | rs2_final;
                    3'b111: alu_result = rs1_final & rs2_final;
                endcase
            end
            7'b0010011: begin
                unique case (funct3)
                    3'b000: alu_result = rs1_final + imm;
                    3'b010: alu_result = ($signed(rs1_final) < $signed(imm)) ? 32'd1 : 32'd0;
                    3'b011: alu_result = (rs1_final < imm) ? 32'd1 : 32'd0;
                    3'b100: alu_result = rs1_final ^ imm;
                    3'b110: alu_result = rs1_final | imm;
                    3'b111: alu_result = rs1_final & imm;
                    3'b001: alu_result = rs1_final << imm[4:0];
                    3'b101: alu_result = (instr_reg[31:25] == 7'b0100000) ? $signed(rs1_final) >>> imm[4:0] : rs1_final >> imm[4:0];
                endcase
            end
            7'b1101111, 7'b1100111: alu_result = pc_reg + 4;
            7'b0110111: alu_result = imm;
            7'b0010111: alu_result = pc_reg + imm;
            7'b0000011, 7'b0100011: alu_result = rs1_final + imm;
        endcase
    end

    logic [31:0] next_pc;
    always_comb begin
        branch_taken = 1'b0;
        next_pc      = pc_reg + 4;
        if (opcode == 7'b1100011) begin
            unique case (funct3)
                3'b000: branch_taken = (rs1_final == rs2_final);
                3'b001: branch_taken = (rs1_final != rs2_final);
                3'b100: branch_taken = ($signed(rs1_final) < $signed(rs2_final));
                3'b101: branch_taken = ($signed(rs1_final) >= $signed(rs2_final));
                3'b110: branch_taken = (rs1_final < rs2_final);
                3'b111: branch_taken = (rs1_final >= rs2_final);
            endcase
            if (branch_taken) next_pc = pc_reg + imm;
        end else if (opcode == 7'b1101111) begin
            next_pc = pc_reg + imm;
        end else if (opcode == 7'b1100111) begin
            next_pc = (rs1_final + imm) & ~32'd1;
        end
    end
    
    logic [15:0] count_in, count_out, previous;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count_in <= 0;
        end else if (valid_reg) begin
            count_in <= count_in + 1;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count_out <= 0;
        end else begin
            if (fwd_valid_out) begin
                count_out <= program_counter_reg_out/4;
            end
        end
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst||cnn_reset) begin
            cnn_reset <= 0;
            was_cnn_instruction <= 0;
            axi_awaddr  = 4'd0;
            axi_awvalid = 0;
            axi_wdata   = 32'd0;
            axi_wvalid  = 0;
            axi_araddr  = 4'd0;
            axi_arvalid = 0; 
        end else begin
            cnn_reset <= 0; 
            if (was_cnn_instruction ) begin
                cnn_reset <= 1; 
            end
        end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) inference_done_d <= 1'b0;
        else     inference_done_d <= inference_done;
    end
    
    assign inference_done_pulse = inference_done && !inference_done_d;
    
    assign computed_result = cnn_ready ? {28'd0, predicted_class_reg} : alu_result;

    assign source_data_reg_out            = rs2_final;
    assign rd_data_reg_out               = computed_result;
    assign instruction_bits_out          = (cnn_ready) ? completed_instr_reg[(program_counter_reg_out/4)-1] : instr_reg ;
    assign rd_out                        = (cnn_ready) ? completed_instr_reg[(program_counter_reg_out/4)-1][11:7] : rd_reg;
    assign rd_valid_out                  = (!is_cnn_instruction || cnn_ready) ? (valid_reg && rd_valid_reg): 0;
    assign program_counter_reg_out       = pc_reg;
    assign next_program_counter_reg_out  = next_pc;
    assign fwd_valid_out                 = stall_out ? 0 :(valid_reg && rd_valid_reg) || (cnn_ready);
    assign fwd_rd_out                    = (cnn_ready) ? completed_instr_reg[(program_counter_in/4)-1][11:7] : rd_reg;
    assign fwd_data_out                  = computed_result;
    assign status_forwards_out           = status_forwards_in;
    assign status_backwards_out          = status_backwards_in;
    assign jump_address_backwards_out    = jump_address_backwards_in;
    assign done_out = instruction_bits_out==32'h11111111 ;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_valid         <= 1'b0;
            displayed_cnn_msg <= 1'b0;
        end else begin
            alu_valid <= 1'b0;

            if (valid_reg) begin
                alu_valid <= 1'b1;

                if (opcode == 7'b0100011 && !is_cnn_instruction && instr_reg !== 32'h00000013 && (instr_reg !== 32'h11111111)) begin
                    $display("[EXECUTE_STAGE] STORE: instr=0x%08h | rs1=x%0d (0x%08h) | rs2=x%0d (0x%08h) | ALU=0x%08h",
                        instruction_bits_out, rs1_id, rs1_final, rs2_id, rs2_final, computed_result);
                        
                end else if (rd_valid_reg && !is_cnn_instruction && instr_reg !== 32'h00000013 && (instr_reg !== 32'h11111111)) begin
                    $display("[EXECUTE_STAGE] instr=0x%08h | rs1=x%0d (0x%08h) | rs2=x%0d (0x%08h) | ALU=0x%08h | rd=x%0d ",
                        instruction_bits_out, rs1_id, rs1_final, rs2_id, rs2_final, computed_result, rd_reg);
                end

                if (is_cnn_instruction) begin
                    $display("[EXECUTE_STAGE] CNN operation detected —> Inference Starting...");
                end

                if (cnn_ready) begin
                    $display("[CNN] Inference Done ");
                    if (predicted_class_reg < 10) $display("[CNN] Predicted Class ID   : %0d", predicted_class_reg);
                    else $display("[CNN] Predicted Class ID   : XX");
                    $display("[EXECUTE_STAGE]  PC=0x%08h | instr=0x%08h | rs1=x%0d (0x%08h) | CNN RESULT =0x%08h | rd=x%0d",
                        program_counter_reg_out, completed_instr_reg[(program_counter_reg_out/4)-1], completed_instr_reg[(program_counter_reg_out/4)-1][19:15] , completed_instr_reg[(program_counter_reg_out/4)-1][19:15] , predicted_class_reg, rd_out);
                    displayed_cnn_msg <= 1;
                end
            end
        end
    end

endmodule
