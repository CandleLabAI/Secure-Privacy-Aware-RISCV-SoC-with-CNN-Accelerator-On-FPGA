module maxpool2d_2x2_stride2_3x_128ch (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [3:0]  read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        CONV_START,
        WAIT_CONV_DONE,
        READ,
        COMPUTE_STORE,
        COMPUTE_MAX,
        WRITE,
        DONE
    } state_t;

    state_t state;

    wire [3:0] conv2d_read_data;
    reg [31:0] conv2d_read_addr;
    reg conv2d_start;
    wire conv2d_done; 

    conv2d_8_8_64_batchnorm_relu6_1x_128ch layer_1_to_20_output (
        .clk(clk),
        .resetn(resetn),
        .start(conv2d_start),
        .read_addr(conv2d_read_addr),
        .read_data(conv2d_read_data),
        .done(conv2d_done)
    );
    
    wire [31:0] bram_dout;
    reg  [31:0] bram_addr_a;
    reg         bram_en_a, bram_en_b;
    reg  [3:0]  bram_we_a;
    reg  [31:0] bram_din_a;

    assign read_data =
        (read_addr[2:0] == 3'd0) ? bram_dout[31:28] :
        (read_addr[2:0] == 3'd1) ? bram_dout[27:24] :
        (read_addr[2:0] == 3'd2) ? bram_dout[23:20] :
        (read_addr[2:0] == 3'd3) ? bram_dout[19:16] :
        (read_addr[2:0] == 3'd4) ? bram_dout[15:12] :
        (read_addr[2:0] == 3'd5) ? bram_dout[11:8]  :
        (read_addr[2:0] == 3'd6) ? bram_dout[7:4]   :
                                   bram_dout[3:0];

    max_pool_3_bram_wrapper maxpool_output_bram_3 (
        .BRAM_PORTA_0_addr(bram_addr_a),
        .BRAM_PORTA_0_clk(clk),
        .BRAM_PORTA_0_din(bram_din_a),
        .BRAM_PORTA_0_dout(),
        .BRAM_PORTA_0_en(bram_en_a),
        .BRAM_PORTA_0_we(bram_we_a),
        .BRAM_PORTB_0_addr((read_addr >> 3) * 4),
        .BRAM_PORTB_0_clk(clk),
        .BRAM_PORTB_0_din(32'd0),
        .BRAM_PORTB_0_dout(bram_dout),
        .BRAM_PORTB_0_en(bram_en_b),
        .BRAM_PORTB_0_we(4'd0)
    );

    reg [3:0] buffer[0:3];
    reg [6:0] ch;
    reg [3:0] row, col;
    reg [2:0] byte_index;
    reg [2:0] max_count;
    reg [31:0] packed_word;
    reg [3:0] max_val;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            bram_addr_a <= 0;
            conv2d_read_addr <= 0;
            bram_din_a <= 0;
            ch <= 0; row <= 0; col <= 0;
            byte_index <= 0; max_count <= 0;
            bram_en_a <= 0; bram_we_a <= 4'd0;
            bram_en_b <= 0;
            conv2d_start <= 0;
            packed_word <= 0;
        end else begin
            bram_en_a <= 0;
            bram_we_a <= 4'd0;
            conv2d_start <= 0;
            done <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        conv2d_start <= 1;
                        state <= CONV_START;
                    end
                end

                CONV_START: begin
                    conv2d_start <= 0;
                    state <= WAIT_CONV_DONE;
                end

                WAIT_CONV_DONE: begin
                    if (conv2d_done) begin
                        ch <= 0; row <= 0; col <= 0;
                        byte_index <= 0; max_count <= 0;
                        packed_word <= 0;
                        state <= READ;
                    end
                end

                READ: begin
                    conv2d_read_addr <= (ch * 64) + (row * 8 + col);
                    state <= COMPUTE_STORE;
                end

                COMPUTE_STORE: begin
                    buffer[byte_index] <= conv2d_read_data;
                    byte_index <= byte_index + 1;
                    if (byte_index == 2'd3) begin
                        state <= COMPUTE_MAX;
                    end else begin
                        conv2d_read_addr <= conv2d_read_addr + 1;
                        state <= READ;
                    end
                end

                COMPUTE_MAX: begin
                    max_val = buffer[0];
                    if (buffer[1] > max_val) max_val = buffer[1];
                    if (buffer[2] > max_val) max_val = buffer[2];
                    if (buffer[3] > max_val) max_val = buffer[3];

                    packed_word[(28 - 4 * max_count) +: 4] <= max_val;
                    max_count <= max_count + 1;
                    byte_index <= 0;

                    if (max_count == 3'd7) begin
                        state <= WRITE;
                    end else begin
                        state <= READ;
                    end
                end

                WRITE: begin
                    bram_addr_a <= (((ch * 16) + ((row >> 1) * 4 + (col >> 1))) >> 3) * 4;
                    bram_din_a <= packed_word;
                    bram_en_a <= 1;
                    bram_we_a <= 4'b1111;
                    packed_word <= 0;
                    max_count <= 0;

                    if (ch == 127 && row == 6 && col == 6) begin
                        state <= DONE;
                    end else begin
                        if (col + 2 >= 8) begin
                            col <= 0;
                            if (row + 2 >= 8) begin
                                row <= 0;
                                ch <= ch + 1;
                            end else begin
                                row <= row + 2;
                            end
                        end else begin
                            col <= col + 2;
                        end
                        state <= READ;
                    end
                end

                DONE: begin
                    done <= 1;
                    bram_en_a <= 0;
                    bram_en_b <= 1;
                    bram_we_a <= 4'b0000;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
