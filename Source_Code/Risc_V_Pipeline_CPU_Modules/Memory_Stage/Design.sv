module memory_stage (
    input logic clk,
    input logic rst,

    wishbone_interface.master wb,

    input logic [31:0]   source_data_in,
    input logic [31:0]   rd_data_in,
    input logic [31:0]   instruction_bits_in,
    input logic [4:0]    rd_in,
    input logic          rd_valid_in,
    input logic [31:0]   program_counter_in,
    input logic [31:0]   next_program_counter_in,

    input logic          stall_in,
    input logic [31:0] address_in,

    output logic [31:0]  source_data_reg_out,
    output logic [31:0]  rd_data_reg_out,
    output logic [31:0]  instruction_bits_out,
    output logic [4:0]   rd_out,
    output logic         rd_valid_out,
    output logic [31:0]  program_counter_reg_out,
    output logic [31:0]  next_program_counter_reg_out,

    output logic         fwd_valid_out,
    output logic [4:0]   fwd_rd_out,
    output logic [31:0]  fwd_data_out,

    input  pipeline_status::forwards_t   status_forwards_in,
    output pipeline_status::forwards_t   status_forwards_out,
    input  pipeline_status::backwards_t  status_backwards_in,
    output pipeline_status::backwards_t  status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    import pipeline_status::*;

    typedef enum logic [1:0] {
        IDLE,
        REQUEST,
        WAIT_ACK
    } mem_fsm_t;

    mem_fsm_t state, next_state;

    logic do_read, do_write;
    logic [3:0] byte_sel;
    logic do_read_latched;

    logic [31:0] wb_data_out;

    always_comb begin
        do_read  = (instruction_bits_in[6:0] == 7'b0000011);  // LOAD
        do_write = (instruction_bits_in[6:0] == 7'b0100011)|| (instruction_bits_in[6:1] == 7'b111111);  // STORE
        byte_sel = 4'b1111;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:     if (do_read || do_write) next_state = REQUEST;
            REQUEST:  next_state = WAIT_ACK;
            WAIT_ACK: if (wb.ack || wb.err) next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            do_read_latched <= 1'b0;
        else if (state == IDLE)
            do_read_latched <= do_read;
    end

    assign wb.cyc      = (state != IDLE);
    assign wb.stb      = (state == REQUEST);
    assign wb.adr      = address_in;
    assign wb.dat_mosi = rd_data_in;
    assign wb.sel      = byte_sel;
    logic do_write_latched;
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            do_write_latched <= 1'b0;
        else if (state == IDLE)
            do_write_latched <= do_write;
    end
    assign wb.we = do_write_latched;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            wb_data_out <= 32'h00000000;
        else if (wb.ack && do_read_latched)
            wb_data_out <= wb.dat_miso;
    end

    always_comb begin
        fwd_valid_out = rd_valid_in;
        fwd_rd_out    = rd_in;
        fwd_data_out  = do_read_latched ? wb_data_out : rd_data_in;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            source_data_reg_out          <= 32'b0;
            rd_data_reg_out              <= 32'b0;
            instruction_bits_out         <= 32'b0;
            rd_out                       <= 5'b0;
            rd_valid_out                 <= 1'b0;
            program_counter_reg_out      <= 32'b0;
            next_program_counter_reg_out <= 32'b0;
        end else if (!stall_in) begin
            source_data_reg_out          <= source_data_in;
            rd_data_reg_out              <= do_read_latched ? wb_data_out : rd_data_in;
            instruction_bits_out         <= instruction_bits_in;
            rd_out                       <= rd_in;
            rd_valid_out                 <= rd_valid_in;
            program_counter_reg_out      <= program_counter_in;
            next_program_counter_reg_out <= next_program_counter_in;
        end
    end

    always_ff @(posedge clk) begin
        if (instruction_bits_in != 32'h00000013 && rd_valid_in && (instruction_bits_in !== 32'h11111111)) begin
            if (instruction_bits_in[6:0] == 7'b0100011) begin
                $display("[MEMORY_STAGE] STORE to address=0x%08h | value=0x%08h", address_in, rd_data_in);

            end else if (do_read_latched ) begin
                $display("[MEMORY_STAGE] PC=0x%08h | Instr=0x%08h | rd=x%0d | MEM_Result=0x%08h",
                         program_counter_in, instruction_bits_in, rd_in, wb_data_out);
            end else begin
                $display("[MEMORY_STAGE] PC=0x%08h | Instr=0x%08h | rd=x%0d | MEM_Result=0x%08h",
                          program_counter_in, instruction_bits_in, rd_in, rd_data_in);
            end
        end
    end
    
    assign status_forwards_out        = status_forwards_in;
    assign status_backwards_out       = status_backwards_in;
    assign jump_address_backwards_out = jump_address_backwards_in;

endmodule
