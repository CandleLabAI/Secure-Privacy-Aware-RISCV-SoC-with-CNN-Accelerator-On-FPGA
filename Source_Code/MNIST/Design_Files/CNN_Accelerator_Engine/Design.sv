module MNIST_CNN_Accelerator_Engine (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire        pipeline,
    output reg  [3:0]  predicted_digit,
    output reg         done,
    input  reg [4:0] input_image_index    
);

    typedef enum logic [2:0] {
        IDLE,
        START_DENSE,
        WAIT_DENSE,
        READ_OUTPUTS,
        START_ARGMAX,
        WAIT_ARGMAX,
        FINISH
    } state_t;

    state_t state;

    reg  dense_start;
    wire dense_done;
    reg  [31:0] read_addr;
    wire [63:0] read_data;

    reg signed [63:0] output_buffer [0:9];
    reg [3:0] index;

    reg argmax_start;
    wire argmax_done;
    wire [3:0] max_index;
    reg [4:0] image [0:50];
    reg [4:0] img;
    integer z,j=0;

    dense_layer_128_to_10 dense_inst (
        .clk(clk),
        .resetn(resetn),
        .start(dense_start),
        .read_addr(read_addr),
        .read_data(read_data),
        .done(dense_done)
    );

    argmax64_10 prediction_output_layer (
    .clk(clk),
    .resetn(resetn),
    .start(argmax_start),
    .data_in0(output_buffer[0]),
    .data_in1(output_buffer[1]),
    .data_in2(output_buffer[2]),
    .data_in3(output_buffer[3]),
    .data_in4(output_buffer[4]),
    .data_in5(output_buffer[5]),
    .data_in6(output_buffer[6]),
    .data_in7(output_buffer[7]),
    .data_in8(output_buffer[8]),
    .data_in9(output_buffer[9]),
    .max_index(max_index),
    .img(img),
    .done(argmax_done)
);

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
            dense_start <= 0;
            argmax_start <= 0;
            read_addr <= 0;
            predicted_digit <= 0;
            done <= 0;
            index <= 0;
            img <=0;
            z <=0;
            for (z=0;z<50;z++) begin
            image[z]<=0;end
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    image[input_image_index] <= input_image_index;
                    if (start) begin
                        img =1;j = 0;
                        for (z=2;z<10;z++) begin
                            if (image[z] == z) begin
                                img = image[z];
                                j=1; end
                            end
                        if (j==0) begin
                            dense_start <= 1;
                            state <= START_DENSE;
                        end
                        else begin
                            if (!pipeline) begin
                                dense_start <= 1;
                                state <= START_DENSE;
                            end
                            else begin state <= START_ARGMAX; end
                        end
                    end
                end

                START_DENSE: begin
                    dense_start <= 0;
                    state <= WAIT_DENSE;
                end

                WAIT_DENSE: begin
                    if (dense_done) begin
                        index <= 0;
                        read_addr <= 0;
                        state <= READ_OUTPUTS;
                    end
                end

                READ_OUTPUTS: begin
                    output_buffer[index] <= read_data;
                    index <= index + 1;
                    read_addr <= read_addr + 16;
                    //$display("ADDR  %0d   DATA  %0d",index,$signed(read_data) );
                    if (index == 9)
                        state <= START_ARGMAX;
                end

                START_ARGMAX: begin
                    argmax_start <= 1;
                    state <= WAIT_ARGMAX;
                end

                WAIT_ARGMAX: begin
                    argmax_start <= 0;
                    if (argmax_done) begin
                        predicted_digit <= max_index;
                        done <= 1;
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    state <= FINISH;
                end
            endcase
        end
    end

endmodule
