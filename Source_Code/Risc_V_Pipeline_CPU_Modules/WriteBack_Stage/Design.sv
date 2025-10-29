module writeback_stage (
    input  logic clk,
    input  logic rst,

    input  logic [31:0] source_data_in,
    input  logic [31:0] rd_data_in,
    input  logic [31:0] instruction_bits_in,
    input  logic [4:0]  rd_in,
    input  logic        rd_valid_in,
    input  logic [31:0] program_counter_in,
    input  logic [31:0] next_program_counter_in,

    input  logic external_interrupt_in,
    input  logic timer_interrupt_in,

    output logic        fwd_valid_out,
    output logic [4:0]  fwd_rd_out,
    output logic [31:0] fwd_data_out,

    output logic        dump_all_regs_out,

    input  logic [3:0] status_forwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    output logic [31:0] jump_address_backwards_out,
    input logic        stall_out,
    input logic        done_in,
    output logic        done_out
);
    import pipeline_status::*;

    logic [31:0] interrupt_vector = 32'h00000010;
    logic [31:0] mret_return_addr;

    logic is_ecall, is_mret;
    logic interrupt_pending;
    logic interrupt_pending_d;
    logic interrupt_le;   
    logic done [1:0];

    assign mret_return_addr = program_counter_in;
    logic [31:0] _dummy_sink;
    assign _dummy_sink = source_data_in ^ next_program_counter_in;

    always_comb begin
        is_ecall = (instruction_bits_in[6:0] == 7'b1110011) && (instruction_bits_in[31:20] == 12'h000);
        is_mret  = (instruction_bits_in[6:0] == 7'b1110011) && (instruction_bits_in[31:20] == 12'h302);
        done [done_in] = done_in;
        interrupt_pending = external_interrupt_in | timer_interrupt_in;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            interrupt_pending_d <= 1'b0;
        else
            interrupt_pending_d <= interrupt_pending;
    end
    assign interrupt_le = interrupt_pending && !interrupt_pending_d;

    assign fwd_valid_out = rd_valid_in;
    assign fwd_rd_out    = rd_in;
    assign fwd_data_out  = rd_data_in;

    logic [6:0] opcode;
    assign opcode = instruction_bits_in[6:0];
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            done_out <= 1'b0;
        else if (done[1]|| done_out)
            done_out <= done[1]|| done_out;
    end
//    assign done_out = done[1]|| done_out;
    
    always_comb begin
        dump_all_regs_out = 1'b0;
    
        if (rd_valid_in && rd_in != 5'd0) begin
            dump_all_regs_out = 1'b1;
        end 
        if (instruction_bits_in==32'h11111111) begin
            dump_all_regs_out = 1'b0;
        end        
        else begin
            case (opcode)
                7'b1101111, // JAL
                7'b1100111, // JALR
                7'b1100011, // Branch
                7'b1110011: // SYSTEM (ECALL, MRET)
                    dump_all_regs_out = 1'b1;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (dump_all_regs_out && (instruction_bits_in !== 32'h11111111)) begin
            $display("[WRITEBACK_STAGE] PC=0x%08h | Instr=0x%08h | rd=x%0d | Value=0x%08h",
                      program_counter_in, instruction_bits_in, rd_in, rd_data_in);
         if (opcode == 7'b1101111 || opcode == 7'b1100111) begin
            $display("[WRITEBACK_STAGE] JUMP Instruction executed");
        end
        
        //$display("[WRITEBACK_STAGE] Time=%0t | rd=%0d | value=0x%08h", $time, rd_in, rd_data_in);

        end

        if (is_ecall)
            $display("[WRITEBACK_STAGE] ECALL detected at PC=0x%08h", program_counter_in);
        if (is_mret)
            $display("[WRITEBACK_STAGE] MRET detected at PC=0x%08h",  program_counter_in);
    end
    
    always_ff @(posedge clk) begin
        if (interrupt_le) begin
        end
    end

    always_comb begin
        status_backwards_out       = READY;
        jump_address_backwards_out = 32'd0;

        if (is_ecall || interrupt_le) begin
            status_backwards_out       = JUMP;
            jump_address_backwards_out = interrupt_vector;
        end else if (is_mret) begin
            status_backwards_out       = JUMP;
            jump_address_backwards_out = mret_return_addr;
        end
    end

endmodule
