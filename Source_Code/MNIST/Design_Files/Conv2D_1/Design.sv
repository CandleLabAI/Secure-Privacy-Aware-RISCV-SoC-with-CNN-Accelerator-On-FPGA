module conv2d_3x3_engine_32ch_pes (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [7:0]  read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        LOAD_IMAGE,
        WAIT_ONE_CYCLE,
        CONV2D_COMPUTE,
        DONE_STATE
    } state_t;

    state_t state;
    reg [1:0] read_delay_counter;
    reg signed [7:0] image_mem[0:783];
    reg signed [7:0] weight_mem[0:287];
    reg signed [7:0] bias_mem[0:31];
    reg signed [7:0] linebuf0[0:27];
    reg signed [7:0] linebuf1[0:27];
    reg signed [7:0] linebuf2[0:27];
    reg signed [7:0] window[0:8];
    reg signed [7:0] curr_weight[0:8];
    reg signed [7:0] curr_bias;
    wire [31:0] conv_out_dout;
    reg [31:0] conv_out_addr_a;
    reg [31:0] conv_out_din_a;
    reg        conv_out_en_a;
    reg [3:0]  conv_out_we_a;
    reg        conv_out_en_b;

    assign read_data =
        (read_addr[1:0] == 2'd0) ? conv_out_dout[31:24] :
        (read_addr[1:0] == 2'd1) ? conv_out_dout[23:16] :
        (read_addr[1:0] == 2'd2) ? conv_out_dout[15:8]  :
                                   conv_out_dout[7:0];

    input_image_bram_wrapper conv2d_3x3_output_26_26_32_bram (
        .BRAM_PORTA_0_addr(conv_out_addr_a),
        .BRAM_PORTA_0_clk(clk),
        .BRAM_PORTA_0_din(conv_out_din_a),
        .BRAM_PORTA_0_dout(),
        .BRAM_PORTA_0_en(conv_out_en_a),
        .BRAM_PORTA_0_we(conv_out_we_a),
        .BRAM_PORTB_0_addr(read_addr),
        .BRAM_PORTB_0_clk(clk),
        .BRAM_PORTB_0_din(32'd0),
        .BRAM_PORTB_0_dout(conv_out_dout),
        .BRAM_PORTB_0_en(conv_out_en_b),
        .BRAM_PORTB_0_we(4'd0)
    );

    integer i, j;
    reg signed [15:0] acc;
    reg [9:0] row, col;
    reg [12:0] out_idx;
    reg [5:0] filter_idx;
    reg [15:0] image_index;
    reg [31:0] packed_data;
    reg [7:0] x;

    reg signed [7:0] a_in[0:8];
    reg signed [7:0] b_in[0:8];
    wire signed [15:0] pe_out[0:8];

    genvar pe_idx;
    generate
        for (pe_idx = 0; pe_idx < 9; pe_idx = pe_idx + 1) begin
            processing_element pe_inst (
                .a(a_in[pe_idx]),
                .b(b_in[pe_idx]),
                .result(pe_out[pe_idx])
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            acc <= 0;
            curr_bias <= 0;
            row <= 0; col <= 0; out_idx <= 0; filter_idx <= 0;
            conv_out_en_a <= 0; conv_out_we_a <= 0; conv_out_en_b <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        row <= 0; col <= 0; out_idx <= 0; filter_idx <= 0;
                        state <= LOAD_IMAGE;
                    end
                end

                LOAD_IMAGE: begin
                    for (j = 0; j < 784; j = j + 1) begin
                        x = image_mem[j];
                    end
                    for (j = 0; j < 28; j = j + 1) begin
                        linebuf0[j] = image_mem[j];
                        linebuf1[j] = image_mem[28 + j];
                        linebuf2[j] = image_mem[56 + j];
                    end
                    state <= WAIT_ONE_CYCLE;
                end

                WAIT_ONE_CYCLE: begin
                    state <= CONV2D_COMPUTE;
                end

                CONV2D_COMPUTE: begin
                    conv_out_en_a <= 0;
                    conv_out_we_a <= 4'b0000;

                    if (row < 26) begin
                        if (col < 26) begin
                            for (i = 0; i < 3; i = i + 1) begin
                                window[i*3 + 0] <= (i == 0) ? linebuf0[col] : (i == 1) ? linebuf1[col] : linebuf2[col];
                                window[i*3 + 1] <= (i == 0) ? linebuf0[col+1] : (i == 1) ? linebuf1[col+1] : linebuf2[col+1];
                                window[i*3 + 2] <= (i == 0) ? linebuf0[col+2] : (i == 1) ? linebuf1[col+2] : linebuf2[col+2];
                            end

                            for (i = 0; i < 9; i = i + 1) begin
                                curr_weight[i] = weight_mem[filter_idx * 9 + i];
                            end
                            curr_bias = bias_mem[filter_idx];

                            for (i = 0; i < 9; i = i + 1) begin
                                a_in[i] <= window[i];
                                b_in[i] <= curr_weight[i];
                            end

                            acc = curr_bias;
                            for (i = 0; i < 9; i = i + 1) begin
                                acc = acc + pe_out[i];
                            end

                            if (acc === 16'hxxxx) acc = 0;

                            case (out_idx % 4)
                                0: packed_data[31:24] <= acc[7:0];
                                1: packed_data[23:16] <= acc[7:0];
                                2: packed_data[15:8]  <= acc[7:0];
                                3: begin
                                    packed_data[7:0] <= acc[7:0];
                                    conv_out_din_a <= packed_data;
                                    conv_out_addr_a <= (((filter_idx * 676) + out_idx) >> 2) * 4;
                                    conv_out_en_a <= 1;
                                    conv_out_we_a <= 4'b1111;
                                end
                            endcase

                            if (out_idx == 675 && (out_idx % 4 != 3)) begin
                                conv_out_din_a <= packed_data;
                                conv_out_addr_a <= (((filter_idx * 676) + out_idx) >> 2) * 4;
                                conv_out_en_a <= 1;
                                case (out_idx % 4)
                                    0: conv_out_we_a <= 4'b0001;
                                    1: conv_out_we_a <= 4'b0011;
                                    2: conv_out_we_a <= 4'b0111;
                                    default: conv_out_we_a <= 4'b1111;
                                endcase
                            end

                            col <= col + 1;
                            out_idx <= out_idx + 1;
                        end else begin
                            col <= 0;
                            row <= row + 1;
                            for (j = 0; j < 28; j = j + 1) begin
                                image_index = ((row + 3) * 28) + j;
                                linebuf0[j] <= linebuf1[j];
                                linebuf1[j] <= linebuf2[j];
                                linebuf2[j] <= image_mem[image_index];
                            end
                        end
                    end else begin
                        if (out_idx % 4 != 0) begin
                            conv_out_din_a <= packed_data;
                            conv_out_addr_a <= (((filter_idx * 676) + out_idx) >> 2) * 4;
                            conv_out_en_a <= 1;
                            case (out_idx % 4)
                                1: conv_out_we_a <= 4'b0001;
                                2: conv_out_we_a <= 4'b0011;
                                3: conv_out_we_a <= 4'b0111;
                                default: conv_out_we_a <= 4'b1111;
                            endcase
                        end

                        if (filter_idx < 31) begin
                            filter_idx <= filter_idx + 1;
                            row <= 0; col <= 0; out_idx <= 0;
                            state <= LOAD_IMAGE;
                        end else begin
                            read_delay_counter <= 3;
                            conv_out_en_a <= 0;
                            conv_out_we_a <= 4'b0000;
                            state <= DONE_STATE;
                        end
                    end
                end

                DONE_STATE: begin
                    if (read_delay_counter > 0) begin
                        read_delay_counter <= read_delay_counter - 1;
                    end else begin
                        conv_out_en_b <= 1;
                        done <= 1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
