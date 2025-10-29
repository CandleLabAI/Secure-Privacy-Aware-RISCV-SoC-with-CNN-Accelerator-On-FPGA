
module max_processing_element (
    input  logic [3:0] in0,
    input  logic [3:0] in1,
    input  logic [3:0] in2,
    input  logic [3:0] in3,
    output logic [3:0] max_out
);
    logic [3:0] max1, max2;

    assign max1 = (in0 > in1) ? in0 : in1;
    assign max2 = (in2 > in3) ? in2 : in3;
    assign max_out = (max1 > max2) ? max1 : max2;
endmodule
