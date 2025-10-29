
module decode_stage (
    input  logic clk,
    input  logic rst,

    input  logic [31:0] instruction_in,
    input  logic [31:0] program_counter_in,
    input  logic        fetch_valid,

    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,

    input  logic        exe_fwd_valid,
    input  logic [4:0]  exe_fwd_rd,
    input  logic [31:0] exe_fwd_data,

    input  logic        mem_fwd_valid,
    input  logic [4:0]  mem_fwd_rd,
    input  logic [31:0] mem_fwd_data,

    input  logic        wb_fwd_valid,
    input  logic [4:0]  wb_fwd_rd,
    input  logic [31:0] wb_fwd_data,
    input  logic stall_pipeline,

    output logic [31:0] rs1_data_reg_out,
    output logic [31:0] rs2_data_reg_out,
    output logic [31:0] program_counter_reg_out,
    output logic [31:0] instruction_out,
    output logic [4:0]  rd_out,
    output logic        rd_valid_out, 
    //output logic        stall_request,

    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out,

    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out
);

    import pipeline_status::*;

    logic [6:0]  opcode;
    logic [4:0]  rs1, rs2, rd;
    logic        rd_valid;

    assign opcode = instruction_in[6:0];
    assign rs1 = instruction_in[19:15];
    assign rd  = instruction_in[11:7];

    assign rs2 = ((opcode == 7'b0110011) || // R-type
              (opcode == 7'b0100011) || // S-type
              (opcode == 7'b1100011))   // B-type
              ? instruction_in[24:20] : 5'd0;
              
    logic [31:0] rs1_data_rf, rs2_data_rf;

    register regfile_inst (
        .clk              (clk),
        .rst              (rst),
        .rs1              (instruction_in[19:15]),
        .rs2              (((instruction_in[6:0] == 7'b0110011) || // R-type
                            (instruction_in[6:0] == 7'b0100011) || // S-type
                            (instruction_in[6:0] == 7'b1100011))   // B-type
                            ? instruction_in[24:20] : 5'd0),
        .rs1_data         (rs1_data_rf),
        .rs2_data         (rs2_data_rf),
        .rd_write_enable  (wb_fwd_valid),
        .rd               (wb_fwd_rd),
        .rd_data          (wb_fwd_data),
        .dump_all_regs    (1'b0) 
    );

    always_comb begin
        unique case (opcode)
            7'b0100011, // STORE
            7'b1100011: // BRANCH
                rd_valid = 1'b0;
            default:
                rd_valid = 1'b1;
        endcase
    end

    logic stall_rs1, stall_rs2;
    always_comb begin
        stall_rs1 = (rs1 != 0) && (
            ((exe_fwd_rd == rs1 && exe_fwd_valid == 0) && exe_fwd_rd != 0) ||
            ((mem_fwd_rd == rs1 && mem_fwd_valid == 0) && mem_fwd_rd != 0)
        );
        
        stall_rs2 = (rs2 != 0) && (
            ((exe_fwd_rd == rs2 && exe_fwd_valid == 0) && exe_fwd_rd != 0) ||
            ((mem_fwd_rd == rs2 && mem_fwd_valid == 0) && mem_fwd_rd != 0)
        );
    end

    //assign stall_request = fetch_valid && (stall_rs1 || stall_rs2);

    logic [31:0] rs1_final, rs2_final;
    logic [4:0]  latched_rs1, latched_rs2;

    always_comb begin
        latched_rs1 = instruction_in[19:15];
        latched_rs2 = ((opcode == 7'b0110011) || // R-type
                      (opcode == 7'b0100011) || // S-type
                      (opcode == 7'b1100011))   // B-type
                      ? instruction_in[24:20] : 5'd0;

        rs1_final = rs1_data_rf;
        rs2_final = rs2_data_rf;


        if (exe_fwd_valid && exe_fwd_rd == latched_rs1 && latched_rs1 != 0) rs1_final = exe_fwd_data;
        else if (mem_fwd_valid && mem_fwd_rd == latched_rs1 && latched_rs1 != 0) rs1_final = mem_fwd_data;
        else if (wb_fwd_valid && wb_fwd_rd == latched_rs1 && latched_rs1 != 0) rs1_final = wb_fwd_data;

        if (exe_fwd_valid && exe_fwd_rd == latched_rs2 && latched_rs2 != 0) rs2_final = exe_fwd_data;
        else if (mem_fwd_valid && mem_fwd_rd == latched_rs2 && latched_rs2 != 0) rs2_final = mem_fwd_data;
        else if (wb_fwd_valid && wb_fwd_rd == latched_rs2 && latched_rs2 != 0) rs2_final = wb_fwd_data;
    end

    assign rs1_data_reg_out        =(opcode == 7'b1111110 || opcode == 7'b1111111) ? instruction_in[19:15] : rs1_final;
    assign rs2_data_reg_out  = (opcode == 7'b1111110 || opcode == 7'b1111111) ? 32'd0 : rs2_final;
    assign program_counter_reg_out = program_counter_in;
    assign instruction_out         = instruction_in;
    assign rd_out                  = (opcode == 7'b1111110 || opcode == 7'b1111111) ? instruction_in[11:7] : rd;
    assign rd_valid_out            = rd_valid && fetch_valid ;
    assign rs2_out           = (opcode == 7'b1111110 || opcode == 7'b1111111) ? 5'd0 : rs2;

    assign status_forwards_out        = status_forwards_in;
    assign status_backwards_out       = status_backwards_in;
    assign jump_address_backwards_out = jump_address_backwards_in;

    always_ff @(posedge clk) begin
        if (fetch_valid  && instruction_in != 32'h00000013 && !stall_pipeline && (instruction_in !== 32'h11111111)) begin
            $display("[DECODE_STAGE] PC=0x%08h | instr=0x%08h | rs1=x%0d | rs2=x%0d | rd=x%0d | rs1_val=0x%08h | rs2_val=0x%08h",
                     program_counter_in+4, instruction_in, instruction_in[19:15], rs2, rd, rs1_data_reg_out, rs2_final);
        end
        
//        $display("[DECODE FWD SELECT] rs1=%0d | rs1_data_in=0x%08h | rs1_final=0x%08h | wb_fwd_valid=%0b | wb_fwd_rd=%0d | wb_fwd_data=0x%08h",
//         rs1, rs1_data_in, rs1_final,
//         wb_fwd_valid, wb_fwd_rd, wb_fwd_data);


    end

endmodule
