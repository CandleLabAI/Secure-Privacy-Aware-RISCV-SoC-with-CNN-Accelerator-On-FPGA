
module CNN_Privacy_mechanism (
    input  logic        clk,
    input  logic        resetn,

    input  logic [3:0]  axi_awaddr,
    input  logic        axi_awvalid,
    input  logic [31:0] axi_wdata,
    input  logic        axi_wvalid,
    input  logic [3:0]  axi_araddr,
    input  logic        axi_arvalid,
    input  logic        pipeline,
    output logic [31:0] axi_rdata,
    output logic        axi_rvalid,

    output logic [3:0]  predicted_class_out,
    output logic        inference_done
);

    // === Internal Signals ===
    logic [3:0] key_input;
    logic       mode_select;       // 0 = MNIST, 1 = CIFAR10
    logic [1:0] axi_master_id;
    logic       write_enable;
    logic [3:0] sig_input;
    logic [3:0] challenge;
    logic       inject_noise;
    logic       inject;
    logic       fsm_locked;
    logic       fsm_error;
    logic       secure_mode_active;
    logic       cnn_start_cmd;
    logic       sig_valid;

    logic [3:0] predicted_class_raw;
    logic       cnn_done;
    logic [3:0] class_after_noise;

    // Data memory interface
    logic [5:0] layer_select;
    logic [17:0] addr;
    logic [7:0] data_out; // 8-bit weights from ROM

    // Output from engines
    logic [3:0] predicted_class_mnist, predicted_class_cifar;
    logic done_mnist, done_cifar;

    // === AXI Privacy Interface ===
    axi_lite_privacy u_axi_if (
        .clk(clk),
        .resetn(resetn),
        .axi_awaddr(axi_awaddr),
        .axi_awvalid(axi_awvalid),
        .axi_wvalid(axi_wvalid),
        .axi_wdata(axi_wdata),
        .axi_araddr(axi_araddr),
        .axi_arvalid(axi_arvalid),
        .axi_rdata(axi_rdata),
        .axi_rvalid(axi_rvalid),
        .key_input(key_input),
        .mode_select(mode_select),
        .axi_master_id(axi_master_id),
        .sig_input(sig_input),
        .challenge(challenge),
        .inject_noise(inject_noise),
        .write_enable(write_enable),
        .fsm_locked(fsm_locked),
        .fsm_error(fsm_error),
        .secure_mode_active(secure_mode_active)
    );

    // === FSM Security ===
    secure_fsm_model u_fsm (
        .clk(clk),
        .resetn(resetn),
        .sig_input(sig_valid),
        .challenge(challenge),
        .write_enable(write_enable),
        .cnn_start_cmd(cnn_start_cmd),
        .secure_mode_active(secure_mode_active),
        .fsm_locked(fsm_locked),
        .fsm_error(fsm_error)
    );

    // === Shared Data Memory ===
    data_memory u_data_mem (
        .clk(clk),
        .mode(mode_select),        // 0 = MNIST, 1 = CIFAR
        .layer_select(layer_select),
        .addr(addr),
        .data_out(data_out)
    );

    // === CNN Engines ===
    MNIST_CNN_Accelerator_Engine u_mnist (
        .clk(clk),
        .resetn(resetn),
        .start(cnn_start_cmd & (mode_select == 1'b0)),
        .pipeline(pipeline),
        .predicted_digit(predicted_class_mnist),
        .done(done_mnist),
        .input_image_index(axi_wdata[20:16]),
        .data_in(data_out),           // from data_memory
        .addr(addr),                  // to data_memory
        .layer_select(layer_select)   // to data_memory
    );

    CIFAR_10_CNN_Accelerator_Engine u_cifar (
        .clk(clk),
        .resetn(resetn),
        .start(cnn_start_cmd & (mode_select == 1'b1)),
        .pipeline(pipeline),
        .predicted_class(predicted_class_cifar),
        .done(done_cifar),
        .input_image_index(axi_wdata[20:16]),
        .data_in(data_out),           // from data_memory
        .addr(addr),                  // to data_memory
        .layer_select(layer_select)   // to data_memory
    );

    // === Mode-based Mux ===
    always_comb begin
        if (mode_select == 1'b0) begin
            predicted_class_raw = predicted_class_mnist;
            cnn_done            = done_mnist;
        end else begin
            predicted_class_raw = predicted_class_cifar;
            cnn_done            = done_cifar;
        end
    end

    // === Signature Verifier ===
    signature_verifier_4bit u_sig_verifier (
        .clk(clk),
        .resetn(resetn),
        .key_input(key_input),
        .mode_select(mode_select),
        .axi_master_id(axi_master_id),
        .sig_input(sig_input),
        .challenge(challenge),
        .start(write_enable), 
        .inject_noise(inject_noise),
        .inject(inject),
        .sig_valid(sig_valid)
    );

    // === Differential Privacy Noise Injector ===
    differential_privacy_noise_injector u_noise (
        .clk(clk),
        .resetn(resetn),
        .inject_noise(inject),
        .class_in(predicted_class_raw),
        .class_out(class_after_noise),
        .cnn_done(cnn_done)
    );

    // === Final Privacy Logic ===
    privacy_logic_model u_privacy (
        .clk(clk),
        .resetn(resetn),
        .secure_mode_active(secure_mode_active),
        .inject_noise(inject),
        .class_in(class_after_noise),
        .class_a(predicted_class_raw),
        .done_in(cnn_done),
        .predicted_class(predicted_class_out),
        .done_out(inference_done)
    );

endmodule
