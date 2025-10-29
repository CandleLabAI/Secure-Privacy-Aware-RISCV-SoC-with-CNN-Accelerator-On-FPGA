module wishbone_led(
    input  logic clk,
    input  logic rst,
    input  logic [6:0] switches,   
    output logic [6:0] leds,
    input  logic [31:0] alu_result_in,
    input  logic        alu_valid_in
);

    logic [31:0] alu_result_store [0:63];
    logic [5:0]  result_index;
    logic [1:0] mode;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            result_index <= 0;
        end else if (alu_valid_in) begin
            alu_result_store[result_index] <= alu_result_in;
            result_index <= result_index + 1;
        end
    end

    assign mode = switches[6:5];

    always_comb begin
        if (switches[4:0] < 64) begin
            leds = alu_result_store[switches[4:0]][6:0];
        end else begin
            leds = 7'h00; 
        end
    end

endmodule
