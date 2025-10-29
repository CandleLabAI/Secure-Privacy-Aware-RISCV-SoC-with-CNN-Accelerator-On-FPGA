
module fetch_stage ( 
    input  logic clk,
    input  logic rst,

    wishbone_interface.master wb,

    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    output pipeline_status::forwards_t status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in,

    input  logic stall_pipeline,
    input  logic        branch_taken_in,
    input  logic [31:0] branch_target_pc_in

);
    import pipeline_status::*;

    logic [31:0] pc;
    logic [31:0] instruction;
    logic        instruction_valid;
    logic        jump_req;

    typedef enum logic [0:0] {
        IDLE,
        REQUEST
    } fsm_t;

    fsm_t state = IDLE, next_state;

    always_comb begin
        jump_req = (status_backwards_in == JUMP);
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else if (!stall_pipeline) begin
            if (jump_req) begin
                pc <= jump_address_backwards_in;
            end else if (state == REQUEST && wb.ack) begin
                pc <= pc + 4;
            end else if (branch_taken_in)
                pc <= branch_target_pc_in;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else if (!stall_pipeline)
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin
                next_state = REQUEST;
            end
            REQUEST: begin
                next_state = wb.ack ? IDLE : REQUEST;
            end
        endcase
//        $display(instruction, instruction_valid, state, wb.ack);
    end

    assign wb.cyc = (state == REQUEST);
    assign wb.stb = (state == REQUEST);
    assign wb.we  = 1'b0;
    assign wb.sel = 4'b1111;
    assign wb.adr = pc;

    logic fetch_hold;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instruction       <= 32'h00000013; 
            instruction_valid <= 0;
            fetch_hold        <= 0;
        end else begin
            if (state == REQUEST && wb.ack && !fetch_hold && !stall_pipeline && (wb.dat_miso !== 32'bx)) begin
                instruction       <= wb.dat_miso;
                instruction_valid <= 1;
                fetch_hold        <= 1;
                if (wb.dat_miso != 32'h00000013 && (wb.dat_miso !== 32'h11111111)) 
                $display("[FETCH_STAGE] Fetched Instruction = 0x%08h at PC = 0x%08h", wb.dat_miso, pc+8);
            end else if (!stall_pipeline && fetch_hold) begin
                instruction_valid <= 0; 
                fetch_hold        <= 0;
            end
        end
    end

    assign instruction_reg_out     = instruction;
    assign program_counter_reg_out = pc;

    assign status_forwards_out = (state == REQUEST && wb.ack && !stall_pipeline)
                                 ? VALID
                                 : BUBBLE;

endmodule
