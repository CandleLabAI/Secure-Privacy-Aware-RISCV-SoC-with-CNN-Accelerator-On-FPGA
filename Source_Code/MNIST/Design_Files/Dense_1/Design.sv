module dense_layer_1600_to_128(
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [31:0] read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        MAX_WAIT,
        LOAD_INPUT,
        COMPUTE,
        STORE,
        DONE
    } state_t;

    state_t state;

    localparam IN_DIM = 1600;
    localparam OUT_DIM = 128;
    localparam CHUNK_SIZE = 200;
    localparam NUM_CHUNKS = 8;

    reg signed [7:0] biases  [0:OUT_DIM-1];
    reg signed [7:0] input_vector [0:IN_DIM-1];
    reg signed [31:0] output_vector [0:OUT_DIM-1];

    integer i;
    reg [7:0] out_idx;
    reg [11:0] in_idx;
    reg [2:0] chunk_idx;

    wire [127:0] bram_dout;
    reg  [31:0] bram_addr_a;
    reg         bram_en_a;
    reg  [15:0] bram_we_a;
    reg  [127:0] bram_din_a;
    reg         bram_en_b;

    assign read_data =
        (read_addr[1:0] == 2'd0) ? bram_dout[127:96] :
        (read_addr[1:0] == 2'd1) ? bram_dout[95:64] :
        (read_addr[1:0] == 2'd2) ? bram_dout[63:32] :
                                   bram_dout[31:0];

    dense_128_bram_wrapper output_bram (
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

    reg [31:0] mp_read_addr;
    wire [7:0] mp_read_data;
    reg        mp_start;
    wire       mp_done;

    maxpool2d_2x2_stride2_64ch_flatten maxpool_inst (
        .clk(clk),
        .resetn(resetn),
        .start(mp_start),
        .read_addr(mp_read_addr),
        .read_data(mp_read_data),
        .done(mp_done)
    );

    // Instantiate 8 ROM modules
    wire [7:0] weights_data [0:7];
    wire [14:0] weights_addr = out_idx * CHUNK_SIZE + in_idx;

    dense_weights_rom_block0 rom0(.addr(weights_addr), .data(weights_data[0]));
    dense_weights_rom_block1 rom1(.addr(weights_addr), .data(weights_data[1]));
    dense_weights_rom_block2 rom2(.addr(weights_addr), .data(weights_data[2]));
    dense_weights_rom_block3 rom3(.addr(weights_addr), .data(weights_data[3]));
    dense_weights_rom_block4 rom4(.addr(weights_addr), .data(weights_data[4]));
    dense_weights_rom_block5 rom5(.addr(weights_addr), .data(weights_data[5]));
    dense_weights_rom_block6 rom6(.addr(weights_addr), .data(weights_data[6]));
    dense_weights_rom_block7 rom7(.addr(weights_addr), .data(weights_data[7]));

    initial begin
        $readmemh("dense_2_biases.hex", biases);
    end

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
            chunk_idx <= 0;
            mp_start <= 0;
            mp_read_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        mp_start <= 1;
                        state <= MAX_WAIT;
                    end
                end
                MAX_WAIT: begin
                    mp_start <= 0;
                    if (mp_done) state <= LOAD_INPUT;
                end
                LOAD_INPUT: begin
                    if (in_idx < IN_DIM) begin
                        mp_read_addr <= in_idx;
                        input_vector[in_idx] <= mp_read_data;
                        in_idx <= in_idx + 1;
                    end else begin
                        in_idx <= 0;
                        chunk_idx <= 0;
                        out_idx <= 0;
                        state <= COMPUTE;
                    end
                end
                COMPUTE: begin
                    if (out_idx < OUT_DIM) begin
                        if (chunk_idx == 0) output_vector[out_idx] = biases[out_idx];
                        output_vector[out_idx] += weights_data[chunk_idx] * input_vector[chunk_idx * CHUNK_SIZE + in_idx];
                        out_idx <= out_idx + 1;
                    end else begin
                        out_idx <= 0;
                        if (chunk_idx < NUM_CHUNKS - 1) begin
                            chunk_idx <= chunk_idx + 1;
                        end else begin
                            state <= STORE;
                        end
                    end
                end
                STORE: begin
                    if (out_idx < OUT_DIM) begin
                        bram_addr_a <= (out_idx >> 2) * 16;
                        case (out_idx % 4)
                            2'd0: bram_din_a[127:96] <= output_vector[out_idx];
                            2'd1: bram_din_a[95:64]  <= output_vector[out_idx];
                            2'd2: bram_din_a[63:32]  <= output_vector[out_idx];
                            2'd3: bram_din_a[31:0]   <= output_vector[out_idx];
                        endcase
                        bram_en_a <= 1;
                        bram_we_a <= 16'hffff;
                        bram_en_b <= 0;
                        out_idx <= out_idx + 1;
                    end else begin
                        bram_en_a <= 0;
                        bram_we_a <= 0;
                        state <= DONE;
                    end
                end
                DONE: begin
                    done <= 1;
                    bram_en_b <= 1;
                end
            endcase
        end
    end
endmodule
