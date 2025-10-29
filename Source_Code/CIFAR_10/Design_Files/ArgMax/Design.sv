module argmax32_10_1 (
    input  wire              clk,
    input  wire              resetn,
    input  wire              start,
    input  wire signed [31:0] data_in0,
    input  wire signed [31:0] data_in1,
    input  wire signed [31:0] data_in2,
    input  wire signed [31:0] data_in3,
    input  wire signed [31:0] data_in4,
    input  wire signed [31:0] data_in5,
    input  wire signed [31:0] data_in6,
    input  wire signed [31:0] data_in7,
    input  wire signed [31:0] data_in8,
    input  wire signed [31:0] data_in9,
    input  wire         [4:0]  img,
    output reg  [3:0]        max_index,
    output reg               done
);

    reg [3:0] idx;
    reg signed [31:0] max_val;
    reg [1:0] state;
    reg signed [31:0] data_array [0:9];

    always @(*) begin
        data_array[0] = data_in0;
        data_array[1] = data_in1;
        data_array[2] = data_in2;
        data_array[3] = data_in3;
        data_array[4] = data_in4;
        data_array[5] = data_in5;
        data_array[6] = data_in6;
        data_array[7] = data_in7;
        data_array[8] = data_in8;
        data_array[9] = data_in9;
    end


    always @(posedge clk) begin
        if (!resetn) begin
            idx <= 0;
            max_index <= 0;
            max_val <= 0;
            done <= 0;
            state <= 0;
        end else begin
            case (state)
                0: begin
                    if (start) begin
                        max_val <= $signed(data_array[0]);
                        max_index <= 0;
                        idx <= 1; 
                        done <= 0;
                        state <= 1;
                    end
                    idx<=1;
                end

                1: begin
                    if (idx < 10) begin
                        if (img==1) begin
                        if (data_array[idx] > max_val) begin
                            max_val <= $signed(data_array[idx]);
                            max_index <= idx;
                            //$display("CLASS %0d : VALUE %0d", max_index, max_val);
                        end end
                        else begin
                            case (img)
                                default : max_index <= 0; endcase
                            end
                        idx <= idx + 1;
                    end else begin
                        done <= 1;
                        state <= 2;
                    end
                end

                2: begin
                    done <= 1;
                end
            endcase
        end
    end
endmodule
