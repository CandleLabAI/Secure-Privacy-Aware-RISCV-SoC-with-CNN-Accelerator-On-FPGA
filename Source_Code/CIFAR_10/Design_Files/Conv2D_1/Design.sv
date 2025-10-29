module conv2d_32_32_3_batchnorm_relu6_1x_32ch(
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [3:0]  read_data,
    output reg         done
);

    parameter IM_W      = 32;
    parameter IM_H      = 32;
    parameter NUM_CH    = 3;
    parameter NUM_FILT  = 32;
    parameter KSIZE     = 3;

    localparam OUT_SIZE   = IM_W * IM_H;
    localparam WEIGHT_NUM = NUM_FILT * NUM_CH * KSIZE * KSIZE;

    typedef enum logic [2:0] {
        IDLE,
        LOAD_IMAGE,
        WAIT_ONE_CYCLE,
        CONV2D_COMPUTE,
        DONE_STATE
    } state_t;

    state_t state;

    reg signed [7:0] image_mem   [0:IM_W*IM_H*NUM_CH-1];
    reg signed [7:0] weight_mem  [0:WEIGHT_NUM-1];
    reg signed [7:0] bias_mem    [0:NUM_FILT-1];
    reg signed [7:0] scale       [0:NUM_FILT-1];
    reg signed [7:0] shift       [0:NUM_FILT-1];

    wire [31:0] conv_out_dout;
    reg  [31:0] conv_out_addr_a, conv_out_din_a;
    reg         conv_out_en_a, conv_out_en_b;
    reg  [3:0]  conv_out_we_a;
    reg [31:0] read_addr_n;

    assign read_data = (read_addr[2:0] == 3'd0) ? conv_out_dout[31:28] :
                       (read_addr[2:0] == 3'd1) ? conv_out_dout[27:24] :
                       (read_addr[2:0] == 3'd2) ? conv_out_dout[23:20] :
                       (read_addr[2:0] == 3'd3) ? conv_out_dout[19:16] :
                       (read_addr[2:0] == 3'd4) ? conv_out_dout[15:12] :
                       (read_addr[2:0] == 3'd5) ? conv_out_dout[11:8]  :
                       (read_addr[2:0] == 3'd6) ? conv_out_dout[7:4]   :
                                                  conv_out_dout[3:0];

    input_output_bram_wrapper conv2d_1x_bram (
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

    integer i, j, idx;
    reg [9:0] row, col;
    reg [12:0] out_idx;
    reg [5:0] filter_idx;
    reg signed [31:0] acc;
    reg [31:0] packed_data;
    reg [1:0] read_delay_counter;
    integer img_idx, weight_idx;
    integer ch_idx;
    integer bn_scaled, relu6_out;

    reg  signed [7:0] a_in[0:26], b_in[0:26];
    wire signed [15:0] pe_result[0:26];

    genvar pe;
    generate
        for (pe = 0; pe < 64; pe = pe + 1) begin : PE_ARRAY
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
            done <= 0;
            conv_out_en_a <= 0;
            conv_out_en_b <= 0;
            conv_out_we_a <= 0;
            row <= 0; col <= 0; out_idx <= 0;
            filter_idx <= 0; acc <= 0; packed_data <= 0;
            read_delay_counter <= 0;
        end else begin
            conv_out_en_a <= 0;
            conv_out_we_a <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        row <= 0; col <= 0; out_idx <= 0;
                        filter_idx <= 0; acc <= 0; packed_data <= 0;
                        state <= LOAD_IMAGE;
                    end
                end

                LOAD_IMAGE: state <= WAIT_ONE_CYCLE;
                WAIT_ONE_CYCLE: state <= CONV2D_COMPUTE;

                CONV2D_COMPUTE: begin
                    if (row < IM_H) begin
                        if (col < IM_W) begin
                            idx = 0;
                            for (ch_idx = 0; ch_idx < NUM_CH; ch_idx = ch_idx + 1) begin
                                for (i = 0; i < 3; i = i + 1) begin
                                    for (j = 0; j < 3; j = j + 1) begin
                                        img_idx = ch_idx * 1024 + (row + i) * IM_W + (col + j);
                                        weight_idx = filter_idx * 27 + ch_idx * 9 + i * 3 + j;
                                        a_in[idx] <= (col + j < IM_W && row + i < IM_H) ? image_mem[img_idx] : 8'd0;
                                        b_in[idx] <= weight_mem[weight_idx];
                                        idx = idx + 1;
                                    end
                                end
                            end

                            acc = 0;
                            for (i = 0; i < 27; i = i + 1)
                                acc = acc + pe_result[i];

                            acc = acc + bias_mem[filter_idx];
                            acc = acc >>> 7;
                            acc = (acc > 127) ? 127 : ((acc < -128) ? -128 : acc);

                            bn_scaled = ((acc * scale[filter_idx]) + shift[filter_idx]) >>> 7;
                            relu6_out = (bn_scaled + 128) >>> 5;
                            relu6_out = (relu6_out > 6) ? 6 : (relu6_out < 0) ? 0 : relu6_out;

                            case (out_idx % 8)
                                0:  packed_data[31:28] = relu6_out[3:0];
                                1:  packed_data[27:24] = relu6_out[3:0];
                                2:  packed_data[23:20] = relu6_out[3:0];
                                3:  packed_data[19:16] = relu6_out[3:0];
                                4:  packed_data[15:12] = relu6_out[3:0];
                                5:  packed_data[11:8]  = relu6_out[3:0];
                                6:  packed_data[7:4]   = relu6_out[3:0];
                                7: begin
                                    packed_data[3:0] = relu6_out[3:0];
                                    conv_out_din_a   = packed_data;
                                    conv_out_addr_a  = ((filter_idx * 1024 + out_idx) >> 3) * 4;
                                    conv_out_en_a    = 1;
                                    conv_out_we_a    = 4'b1111;
                                    packed_data      = 0;
                                end
                            endcase

                            if ((out_idx == 1023) && (out_idx % 8 != 7)) begin
                                conv_out_din_a  <= packed_data;
                                conv_out_addr_a <= ((filter_idx * 1024 + out_idx) >> 3)*4;
                                conv_out_en_a   <= 1;
                                conv_out_we_a   <= 4'b1111;
                            end

                            out_idx <= out_idx + 1;
                            col <= col + 1;
                        end else begin
                            col <= 0;
                            row <= row + 1;
                        end
                    end else begin
                        if (filter_idx < NUM_FILT - 1) begin
                            filter_idx <= filter_idx + 1;
                            row <= 0; col <= 0; out_idx <= 0;
                            acc <= 0; packed_data <= 0;
                        end else begin
                            read_delay_counter <= 3;
                            state <= DONE_STATE;
                        end
                    end
                end

                DONE_STATE: begin
                    if (read_delay_counter > 0)
                        read_delay_counter <= read_delay_counter - 1;
                    else begin
                        conv_out_en_b <= 1;
                        done <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
