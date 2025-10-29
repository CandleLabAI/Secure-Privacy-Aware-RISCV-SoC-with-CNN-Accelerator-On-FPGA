module maxpool2d_2x2_stride2_64ch_flatten (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [7:0]  read_data,
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

    wire [7:0] conv2d_read_data;
    reg  [31:0] conv2d_read_addr;
    reg  conv2d_start;
    wire conv2d_done;

    conv2d_13_13_32_to_11_11_64 conv2d_1_inst (
        .clk(clk),
        .resetn(resetn),
        .start(conv2d_start),
        .read_addr(conv2d_read_addr),
        .read_data(conv2d_read_data),
        .done(conv2d_done)
    );

    wire [31:0] bram_dout;
    reg [31:0] bram_addr_a;
    reg        bram_en_a;
    reg [3:0]  bram_we_a;
    reg [31:0] bram_din_a;

    assign read_data =
        (read_addr[1:0] == 2'd0) ? bram_dout[31:24] :
        (read_addr[1:0] == 2'd1) ? bram_dout[23:16] :
        (read_addr[1:0] == 2'd2) ? bram_dout[15:8] :
                                   bram_dout[7:0];

    max_pool_output_bram_wrapper output_bram (
        .BRAM_PORTA_0_addr(bram_addr_a),
        .BRAM_PORTA_0_clk(clk),
        .BRAM_PORTA_0_din(bram_din_a),
        .BRAM_PORTA_0_dout(),
        .BRAM_PORTA_0_en(bram_en_a),
        .BRAM_PORTA_0_we(bram_we_a),
        .BRAM_PORTB_0_addr(read_addr),
        .BRAM_PORTB_0_clk(clk),
        .BRAM_PORTB_0_din(32'd0),
        .BRAM_PORTB_0_dout(bram_dout),
        .BRAM_PORTB_0_en(done),
        .BRAM_PORTB_0_we(4'd0)
    );

    reg [7:0] buffer [0:3];
    reg [5:0] ch;
    reg [3:0] row, col;
    reg [1:0] byte_index;
    reg [1:0] max_count;
    reg [31:0] packed_word;
    reg [7:0] max_val;

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
            conv2d_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    conv2d_start <= 0;
                    if (start) state <= CONV_START;
                end

                CONV_START: begin
                    conv2d_start <= 1;
                    state <= WAIT_CONV_DONE;
                end

                WAIT_CONV_DONE: begin
                    conv2d_start <= 0;
                    if (conv2d_done) begin
                        ch <= 0; row <= 0; col <= 0;
                        byte_index <= 0; max_count <= 0;
                        conv2d_read_addr <= 0;
                        bram_addr_a <= 0;
                        state <= READ;
                    end
                end

                READ: begin
                    conv2d_read_addr = ((ch * 121) + (row * 11 + col));
                    state <= COMPUTE_STORE;
                end

                COMPUTE_STORE: begin
                    buffer[byte_index] = conv2d_read_data;
                    //$display("ADDR  %0d  DATA  %0h",conv2d_read_addr, conv2d_read_data);
                    byte_index <= byte_index + 1;
                    if (byte_index == 2'd3) begin
                        conv2d_read_addr <= conv2d_read_addr + 1;
                        state <= COMPUTE_MAX;
                        end
                    else begin
                        conv2d_read_addr <= conv2d_read_addr + 1;
                        state <= READ;
                    end
                end

                COMPUTE_MAX: begin
                    max_val = buffer[0];
                    if (buffer[1] > max_val) max_val = buffer[1];
                    if (buffer[2] > max_val) max_val = buffer[2];
                    if (buffer[3] > max_val) max_val = buffer[3];
                    packed_word[((3 - max_count) * 8) +: 8] <= max_val;
                    max_count <= max_count + 1;
                    byte_index <= 0;

                    col <= col + 2;
                    if (col >= 10) begin
                        col <= 0;
                        row <= row + 2;
                        if (row >= 10) begin
                            row <= 0;
                            ch <= ch + 1;
                        end
                    end

                    if (max_count == 2'd3)
                        state <= WRITE;
                    else
                        state <= READ;
                end

                WRITE: begin
                    bram_addr_a = bram_addr_a;
                    bram_din_a = packed_word;
                    bram_en_a = 1;
                    bram_we_a = 4'b1111;
                    max_count = 0;
                    
                    if (bram_addr_a > 1592) begin
                    //$display("ADDR  %0d  DATA  %0h",bram_addr_a, bram_din_a);
                        state = DONE;
                        end
                    else begin
                    //$display("ADDR  %0d  DATA  %0h",bram_addr_a, bram_din_a);
                        bram_addr_a = bram_addr_a +4;
                        state <= READ;
                    end
                end

                DONE: begin
                    bram_en_a <= 0;
                    bram_we_a <= 4'b0;
                    done <= 1;
                    state <= DONE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
