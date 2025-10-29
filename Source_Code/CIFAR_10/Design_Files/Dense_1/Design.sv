module dense_layer_1x_2048_to_128_bn_relu6 (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [6:0]  read_addr,
    output wire [3:0]  read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        MAX_WAIT,
        LOAD_INPUT,
        COMPUTE,
        DONE
    } state_t;

    state_t state;

    localparam IN_DIM = 2048;
    localparam OUT_DIM = 128;
    localparam CHUNK_SIZE = 256;
    localparam NUM_CHUNKS = 8;

    reg signed [7:0] biases [0:OUT_DIM-1];
    reg signed [7:0] scale  [0:OUT_DIM-1];
    reg signed [7:0] shift  [0:OUT_DIM-1];
    reg signed [7:0] input_vector [0:IN_DIM-1];
    reg signed [31:0] acc,temp_acc;
    reg signed [15:0] bn_scaled;
    reg [3:0] relu6_out;

    reg [3:0] output_bram [0:127];
    assign read_data = output_bram[read_addr];

    reg [7:0] out_idx;
    reg [10:0] in_idx;
    reg [2:0] chunk_idx;

    integer i;

    reg [31:0] mp_read_addr;
    wire [3:0] mp_read_data;
    reg        mp_start;
    wire       mp_done;

    maxpool2d_2x2_stride2_3x_128ch layer_1_to_21_output (
        .clk(clk),
        .resetn(resetn),
        .start(mp_start),
        .read_addr(mp_read_addr),
        .read_data(mp_read_data),
        .done(mp_done)
    );

    wire [7:0] weights_data;
    wire [17:0] weights_addr = out_idx * IN_DIM + chunk_idx * CHUNK_SIZE + in_idx;

    dense_weights_rom_block0 rom(.addr(weights_addr), .data(weights_data));

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            in_idx <= 0;
            out_idx <= 0;
            chunk_idx <= 0;
            mp_start <= 0;
            acc <= 0;
            for (i = 0; i < 128; i = i + 1)
                output_bram[i] <= 4'd0;
        end else begin
            done <= 0;
            mp_start <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        mp_start <= 1;
                        state <= MAX_WAIT;
                    end
                end

                MAX_WAIT: begin
                    if (mp_done) begin
                        in_idx <= 0;
                        state <= LOAD_INPUT;
                    end
                end

                LOAD_INPUT: begin
                    mp_read_addr <= in_idx;
                    input_vector[in_idx] <= mp_read_data;
                    //$display("MP READ[%0d] = %0d", in_idx, mp_read_data);
                    if (in_idx == IN_DIM - 1) begin
                        in_idx <= 0;
                        chunk_idx <= 0;
                        out_idx <= 0;
                        acc <= 0;
                        state <= COMPUTE;
                    end else begin
                        in_idx <= in_idx + 1;
                    end
                end

                COMPUTE: begin
                    if (out_idx < OUT_DIM) begin
                        temp_acc <= 0;
                        if (^acc === 1'bx) acc = temp_acc;
                        if (chunk_idx == 0 && in_idx == 0)
                            acc = biases[out_idx];

                        temp_acc = $signed(input_vector[chunk_idx * CHUNK_SIZE + in_idx]) *
                                    $signed(weights_data);
                        //$display("OUT_IDX = %0d | ACC = %d",chunk_idx,acc);
                        acc = acc + temp_acc;
                        if (in_idx == CHUNK_SIZE - 1) begin
                            in_idx <= 0;
                            if (chunk_idx == NUM_CHUNKS - 1) begin
                                acc = (acc) >>> 5;
                                acc = (acc > 127) ? 127 : ((acc < -128) ? -128 : acc);
                                bn_scaled = ((acc * scale[out_idx]) + shift[out_idx]) >>> 7;
                                if (bn_scaled > 127) bn_scaled = 127;
                                if (bn_scaled < -128) bn_scaled = -128;

                                relu6_out = (bn_scaled + 128) / 42;
                                if (relu6_out > 6) relu6_out = 6;
                                if (relu6_out < 0) relu6_out = 0;

                                output_bram[out_idx] <= relu6_out;
                                //$display("OUT_IDX = %0d | Bias=%d Scale=%d Shift=%d", out_idx, biases[out_idx], scale[out_idx], shift[out_idx]);
                                //$display("OUT_IDX = %0d | MAC = %0d | BN = %0d | ReLU6 = %0d ",out_idx, acc, bn_scaled, relu6_out);

                                if (out_idx == OUT_DIM - 1) begin
                                    state <= DONE;
                                end else begin
                                    out_idx <= out_idx + 1;
                                    chunk_idx <= 0;
                                    acc <= 0;
                                end
                            end else begin
                                chunk_idx <= chunk_idx + 1;
                            end
                        end else begin
                            in_idx <= in_idx + 1;
                        end
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
