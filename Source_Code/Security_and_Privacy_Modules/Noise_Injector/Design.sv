module differential_privacy_noise_injector (
    input  logic        clk,
    input  logic        resetn,
    input  logic        inject_noise,
    input  logic [3:0]  class_in,
    input  logic        cnn_done,
    output logic [3:0]  class_out
);

    logic [3:0] lfsr;
    logic high_noise [0:1];
    integer i;
    
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            lfsr <= 4'b1111;
            high_noise[0] <=0;
            high_noise[1] <=0;
        end
        else begin
            high_noise[inject_noise] <= inject_noise;
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[1]};
        end
    end

    logic [3:0] noise;
    assign noise = class_in ^ lfsr; 

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
            class_out <= 4'b0000;
        else if (high_noise[1] && cnn_done) begin
            class_out = class_in ^ noise; 
        end
        else
            class_out <= class_in;         
    end

endmodule
