module conv2d_13_13_32_to_11_11_64(
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [31:0] read_addr,
    output wire [7:0]  read_data,
    output reg         done
);

    typedef enum logic [2:0] {
        IDLE,
        WAIT_FOR_MAXPOOL,
        CONVOLVE,
        MAC_WAIT,     
        MAC_CALC,     
        STORE,
        FINISH
    } state_t;

    state_t state;

    localparam IC = 32;
    localparam OC = 64;
    localparam K = 3;
    localparam IN_H = 13;
    localparam IN_W = 13;
    localparam OUT_H = 11;
    localparam OUT_W = 11;

    reg signed [7:0] weights [0:OC*IC*K*K-1];
    reg signed [7:0] biases [0:OC-1];
    reg        maxpool_start;
    wire       maxpool_done;

    reg [5:0] oc, ic, ic_reg;
    reg [3:0] i, j;
    reg [3:0] x, y;
    reg signed [7:0] acc, acc_reg;
    reg [31:0] weight_idx, weight_idx_reg;
    reg [31:0] input_base;
    reg [1:0] byte_count, i_reg, j_reg;
    reg [31:0] pack;
    reg [31:0] input_addr;

    reg convolve_done;
    reg [2:0] mac_state;

    wire [31:0] conv_out_dout;
    reg  [31:0] conv_out_addr_a;
    reg  [31:0] conv_out_din_a;
    reg         conv_out_en_a;
    reg  [3:0]  conv_out_we_a;
    reg         conv_out_en_b;

    wire [7:0] input_data;

    maxpool2d_2x2_stride2_32ch maxpool_inst (
        .clk(clk),
        .resetn(resetn),
        .start(maxpool_start),
        .read_addr(input_addr),
        .read_data(input_data),
        .done(maxpool_done) 
    );

    conv2d_64ch_output_bram_wrapper conv2d_1_output_bram (
        .BRAM_PORTA_0_addr (conv_out_addr_a),
        .BRAM_PORTA_0_clk  (clk),
        .BRAM_PORTA_0_din  (conv_out_din_a),
        .BRAM_PORTA_0_dout (),
        .BRAM_PORTA_0_en   (conv_out_en_a),
        .BRAM_PORTA_0_we   (conv_out_we_a),

        .BRAM_PORTB_0_addr (read_addr),
        .BRAM_PORTB_0_clk  (clk),
        .BRAM_PORTB_0_din  (32'd0),
        .BRAM_PORTB_0_dout (conv_out_dout),
        .BRAM_PORTB_0_en   (conv_out_en_b),
        .BRAM_PORTB_0_we   (4'd0)
    );

    assign read_data =
        (read_addr[1:0] == 2'd0) ? conv_out_dout[31:24]   :
        (read_addr[1:0] == 2'd1) ? conv_out_dout[23:16]  :
        (read_addr[1:0] == 2'd2) ? conv_out_dout[15:8] :
                                   conv_out_dout[7:0];

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done <= 0;
            acc <= 0;
            byte_count <= 0;
            input_addr <= 0;
            input_base <= 0;
            conv_out_en_b <= 0;
            conv_out_en_a <= 0;
            pack <= 0;
            conv_out_addr_a <= 0;
            conv_out_we_a <= 4'b0000;
            oc <= 0; x <= 0; y <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    maxpool_start <= 0;
                    if (start) begin
                        maxpool_start <= 1;
                        state <= WAIT_FOR_MAXPOOL;
                    end
                end

                WAIT_FOR_MAXPOOL: begin
                    maxpool_start <= 0;
                    if (maxpool_done) begin
                        oc <= 0; x <= 0; y <= 0;
                        conv_out_addr_a <= 0;
                        state <= CONVOLVE;
                    end
                end

                CONVOLVE: begin
                    acc_reg <= biases[oc];
                    ic_reg <= 0; i_reg <= 0; j_reg <= 0;
                    state <= MAC_WAIT;
                end

                MAC_WAIT: begin
                    input_base <= (ic_reg * IN_H * IN_W) + ((y + i_reg) * IN_W + (x + j_reg));
                    input_addr <= input_base;
                    weight_idx_reg <= (((oc * IC + ic_reg) * K + i_reg) * K + j_reg);
                    state <= MAC_CALC;
                end

                MAC_CALC: begin
                    acc_reg <= acc_reg + $signed(input_data) * $signed(weights[weight_idx_reg]);
                    if (j_reg < K - 1) begin
                        j_reg = j_reg + 1;
                        state <= MAC_WAIT;
                    end else begin
                        j_reg <= 0;
                        if (i_reg < K - 1) begin
                            i_reg = i_reg + 1;
                            state <= MAC_WAIT;
                        end else begin
                            i_reg <= 0;
                            if (ic_reg < IC - 1) begin
                                ic_reg = ic_reg + 1;
                                state <= MAC_WAIT;
                            end else begin
                                acc = acc_reg;
                                state <= STORE;
                            end
                        end
                    end
                end

                STORE: begin
                    case (byte_count)
                        0: pack[31:24] <= acc;
                        1: pack[23:16] <= acc;
                        2: pack[15:8]  <= acc;
                        3: pack[7:0]   <= acc;
                    endcase
                    byte_count <= byte_count + 1;
                    
                    if (byte_count == 2'd3) begin
                        conv_out_addr_a = conv_out_addr_a;
                        conv_out_din_a = pack;
                        conv_out_en_a = 1;
                        conv_out_we_a = 4'b1111;
                        conv_out_addr_a = conv_out_addr_a + 4;
                        byte_count <= 0;

                        if (oc < OC-4) begin
                            oc = oc + 4;
                        end else begin
                            oc <= 0;
                            if (x < OUT_W-1) begin 
                                x = x + 1;
                            end else begin
                                x <= 0;
                                if (y < OUT_H - 1) begin y <= y + 1;
                                    end
                                else begin
                                    y <= 0;
                                end
                            end
                        end
                        if (conv_out_addr_a<7740) begin
                        state = CONVOLVE;
                        end
                        if (conv_out_addr_a==7740) begin
                            state = FINISH;
                        end
                    end
                end

                FINISH: begin
                    done <= 1;
                    conv_out_en_a <= 0;
                    conv_out_we_a <= 4'b0000;
                    conv_out_en_b <= 1;
                    state <= FINISH;
                end
                default : state <= IDLE;
            endcase
        end
    end
endmodule
