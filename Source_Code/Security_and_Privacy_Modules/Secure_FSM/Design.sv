module secure_fsm_model (
    input  logic        clk,
    input  logic        resetn,
    input  logic        sig_input,
    input  logic [3:0]  challenge,
    input  logic        write_enable,
    output logic        cnn_start_cmd,
    output logic        secure_mode_active,
    output logic        fsm_locked,
    output logic        fsm_error
);

    // FSM States
    typedef enum logic [1:0] {
        STATE_IDLE     = 2'b00,
        STATE_VERIFY   = 2'b01,
        STATE_UNLOCKED = 2'b10,
        STATE_ERROR    = 2'b11
    } state_t;

    state_t state, next_state;

    // FSM State Transition
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end
    
    always_comb begin
        next_state     = state;
        cnn_start_cmd  = 1'b0;
        case (state)
            STATE_IDLE: begin
                if (write_enable)
                    next_state = STATE_VERIFY;
            end

            STATE_VERIFY: begin
                if (sig_input != 0) begin
                    next_state = STATE_UNLOCKED;
                end else begin
                    next_state = STATE_ERROR;
                end
            end

            STATE_UNLOCKED: begin
                next_state    = STATE_UNLOCKED;
                cnn_start_cmd = 1'b1;
            end

            STATE_ERROR: begin
                next_state = STATE_ERROR;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // FSM Output Logic
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            fsm_locked         <= 1'b1;
            fsm_error          <= 1'b0;
            secure_mode_active <= 1'b0;
        end else begin
            unique case (next_state)
                STATE_IDLE: begin
                    fsm_locked         <= 1'b1;
                    fsm_error          <= 1'b0;
                    secure_mode_active <= 1'b0;
                end

                STATE_VERIFY: begin
                    fsm_locked         <= 1'b1;
                    fsm_error          <= 1'b0;
                    secure_mode_active <= 1'b0;
                end

                STATE_UNLOCKED: begin
                    fsm_locked         <= 1'b0;
                    fsm_error          <= 1'b0;
                    secure_mode_active <= 1'b1;
                end

                STATE_ERROR: begin
                    fsm_locked         <= 1'b1;
                    fsm_error          <= 1'b1;
                    secure_mode_active <= 1'b0;
                end

                default: begin
                    fsm_locked         <= 1'b1;
                    fsm_error          <= 1'b0;
                    secure_mode_active <= 1'b0;
                end
            endcase
        end
    end

endmodule
