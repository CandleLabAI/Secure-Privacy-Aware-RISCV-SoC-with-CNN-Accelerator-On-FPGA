module privacy_logic_model (
    input  logic        clk,
    input  logic        resetn,
    input  logic        secure_mode_active,
    input  logic        inject_noise,
    input  logic [3:0]  class_in,     
    input  logic [3:0]  class_a,
    input  logic        done_in,
    output logic [3:0]  predicted_class,
    output logic        done_out
);

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            predicted_class <= 4'b00;
            done_out        <= 1'b0;
        end else begin
            done_out <= done_in;

            if (done_in) begin
                predicted_class <= (secure_mode_active && inject_noise) ? class_in : class_a;
                //$display("with noise %0d, without noise %0d",class_in , class_a);
            end
        end
    end

endmodule
