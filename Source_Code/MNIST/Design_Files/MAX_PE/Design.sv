module mac_processing_element (
    input  logic clk,
    input  logic signed [7:0] a,
    input  logic signed [7:0] b,
    input  logic signed [15:0] acc_in,
    output logic signed [15:0] result
);
    logic signed [15:0] mul_result;
    logic signed [15:0] acc_reg;

    always_ff @(posedge clk) begin
        mul_result <=  $signed(a) * $signed(b);
    end

    always_ff @(posedge clk) begin
        acc_reg <= acc_in + mul_result; 
    end

    assign result = acc_reg;
endmodule
