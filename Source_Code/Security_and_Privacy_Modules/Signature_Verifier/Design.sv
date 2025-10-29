module signature_verifier_4bit #(
    parameter logic [3:0] SECRET_KEY = 4'hA
) (
    input  logic        clk,
    input  logic        resetn,
    input  logic [3:0]  sig_input,
    input  logic [3:0]  key_input,
    input  logic        mode_select,
    input  logic [1:0]  axi_master_id,
    input  logic [3:0]  challenge,
    input  logic        inject_noise,
    input  logic        start,
    output logic        sig_valid,
    output logic inject
);

    logic [15:0] salted_challenge;
    logic [3:0] expected_sig;

    // Compute salted challenge and expected signature
    assign salted_challenge = {inject_noise,mode_select,axi_master_id,key_input,sig_input,1'b0,challenge[3:1]} ;
    assign expected_sig      = salted_challenge[3:0] ^ SECRET_KEY;

    // Signature verification logic
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin 
            sig_valid <= 1'b0;
            inject <= 1'b0; end
        else if (start) begin 
            sig_valid <= (salted_challenge[7:4] == expected_sig)&&(salted_challenge[14]==1'b1)&&(salted_challenge[13:12]==2'b10)&&(salted_challenge[11:8]==4'b1010);
            if (salted_challenge[15]==1) inject<=1;
     end
     end

endmodule
