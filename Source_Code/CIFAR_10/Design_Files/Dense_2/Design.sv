
module dense_layer_2x_128_to_10 (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire [3:0] read_addr,
    output wire [31:0] read_data,
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

    localparam IN_DIM  = 128;
    localparam OUT_DIM = 10;

    reg signed [7:0] weights  [0:(IN_DIM * OUT_DIM)-1];
    reg signed [7:0] biases   [0:OUT_DIM-1];
    reg signed [7:0] input_vector [0:IN_DIM-1];
    reg [31:0] output_bram [0:OUT_DIM-1];

    integer i;
    reg [3:0] out_idx;
    reg [7:0] in_idx;
    integer sum=0;

    assign read_data = output_bram[read_addr];

    reg [6:0] dense_read_addr;
    wire [3:0] dense_read_data;
    reg        dense_start;
    wire       dense_done;

   dense_layer_1x_2048_to_128_bn_relu6 layer_1_to_23_output (
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
            out_idx <= 0;
            in_idx <= 0;
            dense_start <= 0;
            dense_read_addr <= 0;
            for (i = 0; i < IN_DIM; i = i + 1)
                input_vector[i] <= 0;
            for (i = 0; i < OUT_DIM; i = i + 1)
                output_bram[i] <= 32'd0;
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
                        dense_read_addr <= in_idx;
                        input_vector[in_idx] <= dense_read_data;
                        in_idx <= in_idx + 1;
                    end else begin
                        in_idx <= 0;
                        out_idx <= 0;
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    if (out_idx < OUT_DIM) begin
                        sum = biases[out_idx];
                        for (i = 0; i < IN_DIM; i = i + 1) begin
                            sum = sum + weights[out_idx * IN_DIM + i] * input_vector[i];
                            //$display("OUT_IDX = %0d | Bias=%d Weight=%d Sum=%d", out_idx, biases[out_idx], weights[out_idx * IN_DIM + i], sum);
                        end
                        output_bram[out_idx] <= sum;
                        out_idx <= out_idx + 1;
                    end else begin
                        out_idx <= 0;
                        state <= STORE;
                    end
                end

                STORE: begin
                    done <= 1;
                    state <= DONE;
                end

                DONE: begin
                    done <= 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
