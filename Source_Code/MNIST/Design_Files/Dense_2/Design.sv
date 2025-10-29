module dense_layer_128_to_10(
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [63:0] read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        WAIT_PREV,
        LOAD_INPUT,
        COMPUTE,
        STORE,
        DONE
    } state_t;

    state_t state;

    localparam IN_DIM = 128;
    localparam OUT_DIM = 10;

    reg signed [7:0] weights [0:OUT_DIM-1][0:IN_DIM-1];
    reg signed [7:0] biases  [0:OUT_DIM-1];
    reg signed [31:0] input_vector [0:IN_DIM-1];
    reg signed [127:0] output_vector [0:OUT_DIM-1];

    integer i;
    reg [3:0] out_idx;
    reg [7:0] in_idx;

    wire [127:0] bram_dout;
    reg  [31:0] bram_addr_a;
    reg         bram_en_a;
    reg  [15:0] bram_we_a;
    reg  [127:0] bram_din_a;
    reg         bram_en_b;

    assign read_data = bram_dout[63:0];

    dense_128_bram_wrapper dense_last_10_bram (
        .BRAM_PORTA_0_addr(bram_addr_a),
        .BRAM_PORTA_0_clk(clk),
        .BRAM_PORTA_0_din(bram_din_a),
        .BRAM_PORTA_0_dout(),
        .BRAM_PORTA_0_en(bram_en_a),
        .BRAM_PORTA_0_we(bram_we_a),
        .BRAM_PORTB_0_addr(read_addr),
        .BRAM_PORTB_0_clk(clk),
        .BRAM_PORTB_0_din(128'd0),
        .BRAM_PORTB_0_dout(bram_dout),
        .BRAM_PORTB_0_en(bram_en_b),
        .BRAM_PORTB_0_we(16'd0)
    );

    reg [31:0] dense_read_addr;
    wire [31:0] dense_read_data;
    reg        dense_start;
    wire       dense_done;

    dense_layer_1600_to_128 dense1_inst (
        .clk(clk),
        .resetn(resetn),
        .start(dense_start),
        .read_addr(dense_read_addr),
        .read_data(dense_read_data),
        .done(dense_done)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            bram_en_a <= 0;
            bram_we_a <= 0;
            bram_addr_a <= 0;
            bram_din_a <= 0;
            out_idx <= 0;
            in_idx <= 0;
            dense_start <= 0;
            dense_read_addr <= 0;
            for (i = 0; i < IN_DIM; i = i + 1)
                input_vector[i] <= 0;
            for (i = 0; i < OUT_DIM; i = i + 1)
                output_vector[i] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        dense_start <= 1;
                        state <= WAIT_PREV;
                    end
                end

                WAIT_PREV: begin
                    dense_start <= 0;
                    if (dense_done)
                        state <= LOAD_INPUT;
                end

                LOAD_INPUT: begin
                    if (in_idx < IN_DIM) begin
                        dense_read_addr = in_idx;
                        input_vector[in_idx] = dense_read_data;
                        //$display("addr %0d  data %0h",dense_read_addr,dense_read_data);
                        in_idx = in_idx + 1;
                    end else begin
                        in_idx <= 0;
                        out_idx <= 0;
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    if (out_idx < OUT_DIM) begin
                        output_vector[out_idx] <= biases[out_idx];
                        for (i = 0; i < IN_DIM; i = i + 1) 
                            output_vector[out_idx] <= output_vector[out_idx] + weights[out_idx][i] * input_vector[i];
                        out_idx <= out_idx + 1;
                    end else begin
                        out_idx <= 0;
                        state <= STORE;
                    end
                end

                STORE: begin
                    if (out_idx < OUT_DIM) begin
                        bram_addr_a <= out_idx * 16;
                        bram_din_a[127:0] <= output_vector[out_idx];
                        bram_en_a <= 1;
                        bram_we_a <= 16'hFFFF;
                        bram_en_b <= 0;
                        out_idx <= out_idx + 1;
                    end else begin
                        bram_en_a <= 0;
                        bram_we_a <= 0;
                        state <= DONE;
                    end
                end

                DONE: begin
                    bram_en_a <= 0;
                    bram_we_a <= 0;
                    bram_en_b <= 1;
                    done <= 1;
                    state <= DONE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
