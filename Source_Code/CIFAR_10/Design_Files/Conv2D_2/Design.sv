module conv2d_16_16_32_batchnorm_relu6_1x_64ch(
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [3:0]  read_data,
    output reg         done
);

    parameter INPUT_W  = 16;
    parameter INPUT_H  = 16;
    parameter IN_CH    = 32;
    parameter OUT_CH   = 64;
    parameter KERNEL   = 3;

    typedef enum logic [3:0] {
        IDLE,
        START_POOL,
        WAIT_POOL_DONE,
        LOAD_LAYER,
        CONV2D,
        LOAD_WINDOW_0,
        WAIT_FOR_READ0,
        WAIT_FOR_READ1,
        WAIT_FOR_READ2,
        MUL_ACCUMULATE,
        POST_PROCESS,
        DONE_STATE
    } state_t;

    state_t state;

    reg pool_start;
    wire pool_done;
    reg [31:0] pool_read_addr;
    wire [3:0] pool_read_data;

    maxpool2d_2x2_stride2_1x_32ch layer_1_to_7_output (
        .clk(clk),
        .resetn(resetn),
        .start(pool_start),
        .read_addr(pool_read_addr),
        .read_data(pool_read_data),
        .done(pool_done)
    );

    reg  [31:0] conv_out_addr_a;
    reg  [31:0] conv_out_din_a;
    wire [31:0] conv_out_dout;
    reg         conv_out_en_a, conv_out_en_b;
    reg  [3:0]  conv_out_we_a;

    second_order_conv_bram_wrapper conv2d_2_1x_bram (
        .BRAM_PORTA_0_addr(conv_out_addr_a),
        .BRAM_PORTA_0_clk(clk),
        .BRAM_PORTA_0_din(conv_out_din_a),
        .BRAM_PORTA_0_dout(),
        .BRAM_PORTA_0_en(conv_out_en_a),
        .BRAM_PORTA_0_we(conv_out_we_a),
        .BRAM_PORTB_0_addr((read_addr >> 3) * 4),
        .BRAM_PORTB_0_clk(clk),
        .BRAM_PORTB_0_din(32'd0),
        .BRAM_PORTB_0_dout(conv_out_dout),
        .BRAM_PORTB_0_en(conv_out_en_b),
        .BRAM_PORTB_0_we(4'd0)
    );

    assign read_data =
        (read_addr[2:0] == 3'd0) ? conv_out_dout[31:28] :
        (read_addr[2:0] == 3'd1) ? conv_out_dout[27:24] :
        (read_addr[2:0] == 3'd2) ? conv_out_dout[23:20] :
        (read_addr[2:0] == 3'd3) ? conv_out_dout[19:16] :
        (read_addr[2:0] == 3'd4) ? conv_out_dout[15:12] :
        (read_addr[2:0] == 3'd5) ? conv_out_dout[11:8]  :
        (read_addr[2:0] == 3'd6) ? conv_out_dout[7:4]   :
                                   conv_out_dout[3:0];

    reg signed [7:0] weight_mem [0:(IN_CH*OUT_CH*KERNEL*KERNEL)-1];
    reg signed [7:0] bias_mem   [0:OUT_CH-1];
    reg signed [7:0] scale      [0:OUT_CH-1];
    reg signed [7:0] shift      [0:OUT_CH-1];

    reg [5:0] ch, filter_idx;
    reg [4:0] row, col;
    reg [10:0] out_idx;
    reg signed [31:0] acc;
    reg [31:0] packed_data;
    reg [3:0] relu6_out;
    reg signed [15:0] bn_scaled;
    reg [3:0] window [0:8];
    reg [15:0] weight_idx;
    integer i;

  logic [7:0] a_in [0:127];
  logic [7:0] b_in [0:127];
  wire signed [15:0] pe_result [0:127];

    genvar pe;
    generate
      for (pe = 0; pe < 128; pe = pe + 1) begin : PE_ARRAY
            processing_element pe_inst (
                .a(a_in[pe]),
                .b(b_in[pe]),
                .result(pe_result[pe])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            pool_start <= 0;
            done <= 0;
            conv_out_en_a <= 0;
            conv_out_we_a <= 0;
            conv_out_en_b <= 0;
            row <= 0;
            col <= 0;
            out_idx <= 0;
            filter_idx <= 0;
            ch <= 0;
            acc <= 0;
            packed_data <= 0;
        end else begin
            pool_start <= 0;
            conv_out_en_a <= 0;
            conv_out_we_a <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) state <= START_POOL;
                end

                START_POOL: begin
                    pool_start <= 1;
                    state <= WAIT_POOL_DONE;
                end

                WAIT_POOL_DONE: begin
                    pool_start <= 0;
                    if (pool_done) begin
                        row <= 0;
                        col <= 0;
                        out_idx <= 0;
                        filter_idx <= 0;
                        ch <= 0;
                        acc <= 0;
                        packed_data <= 0;
                        state <= LOAD_LAYER;
                    end
                end

                LOAD_LAYER: begin
                    conv_out_en_b <= 0;
                    state <= CONV2D;
                end

                CONV2D: begin
                    if (row < INPUT_H) begin
                        if (col < INPUT_W) begin
                            state <= LOAD_WINDOW_0;
                        end else begin
                            col <= 0;
                            row <= row + 1;
                        end
                    end else begin
                        if (filter_idx < OUT_CH - 1) begin
                            filter_idx <= filter_idx + 1;
                            row <= 0;
                            col <= 0;
                            out_idx <= 0;
                        end else begin
                            state <= DONE_STATE;
                        end
                    end
                end

                LOAD_WINDOW_0: begin
                    i = 0;
                    state <= WAIT_FOR_READ0;
                end

                WAIT_FOR_READ0: begin
                    pool_read_addr <= (0 * 256 + (row + i) * 16 + col);
                    window[i*3+0] <= pool_read_data;
                    pool_read_addr <= (0 * 256 + (row + i) * 16 + col + 1);
                    window[i*3+1] <= pool_read_data;
                    pool_read_addr <= (0 * 256 + (row + i) * 16 + col + 2);
                    window[i*3+2] <= pool_read_data;
                    i = i + 1;
                    if (i == 3) state <= MUL_ACCUMULATE;
                    else state <= WAIT_FOR_READ0;
                end

                MUL_ACCUMULATE: begin
                    for (int c = 0; c < 32; c = c + 1) begin
                        for (int k = 0; k < 9; k = k + 1) begin
                            a_in[c*9 + k] <= window[k];
                            b_in[c*9 + k] <= weight_mem[(filter_idx * 288) + (c * 9) + k];
                        end
                    end

                    acc = 0;
                  for (i = 0; i < 128; i = i + 1) begin
                        acc = acc + pe_result[i];
                    end
                    state <= POST_PROCESS;
                end

                POST_PROCESS: begin
                    acc = (acc + bias_mem[filter_idx]) >>> 4;
                    acc = (acc > 127) ? 127 : ((acc < -128) ? -128 : acc);
                    bn_scaled = ((acc * scale[filter_idx]) + shift[filter_idx]) >>> 6;
                    bn_scaled = (bn_scaled > 127) ? 127 : ((bn_scaled < -128) ? -128 : bn_scaled);
                    relu6_out = (bn_scaled + 128) >>> 5;
                    if (relu6_out > 6) relu6_out = 6;
                    if (relu6_out < 0) relu6_out = 0;

                    case (out_idx % 8)
                        0: packed_data[31:28] = relu6_out[3:0];
                        1: packed_data[27:24] = relu6_out[3:0];
                        2: packed_data[23:20] = relu6_out[3:0];
                        3: packed_data[19:16] = relu6_out[3:0];
                        4: packed_data[15:12] = relu6_out[3:0];
                        5: packed_data[11:8]  = relu6_out[3:0];
                        6: packed_data[7:4]   = relu6_out[3:0];
                        7: begin
                            packed_data[3:0] = relu6_out[3:0];
                            conv_out_din_a = packed_data;
                            conv_out_addr_a = ((filter_idx * 256 + out_idx) >> 3) * 4;
                            conv_out_en_a = 1;
                            conv_out_we_a = 4'b1111;
                            packed_data = 0;
                        end
                    endcase

                    if ((out_idx == 255) && (out_idx % 8 != 7)) begin
                        conv_out_din_a <= packed_data;
                        conv_out_addr_a <= ((filter_idx * 256 + out_idx) >> 3) * 4;
                        conv_out_en_a <= 1;
                        conv_out_we_a <= 4'b1111;
                    end

                    out_idx <= out_idx + 1;
                    col <= col + 1;
                    state <= CONV2D;
                end

                DONE_STATE: begin
                    done <= 1;
                    conv_out_en_a <= 0;
                    conv_out_we_a <= 0;
                    conv_out_en_b <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
