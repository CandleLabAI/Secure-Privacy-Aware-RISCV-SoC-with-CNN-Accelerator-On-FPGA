module CNN_Privacy_tb;

    logic clk;
    logic resetn;

    logic [3:0]  axi_awaddr;
    logic        axi_awvalid;
    logic [31:0] axi_wdata;
    logic        axi_wvalid;
    logic [3:0]  axi_araddr;
    logic        axi_arvalid;
    logic [31:0] axi_rdata;
    logic        axi_rvalid;

    logic [3:0] predicted_class_out;
    logic       inference_done;

    Top_Module dut (
        .clk(clk),
        .resetn(resetn),
        .axi_awaddr(axi_awaddr),
        .axi_awvalid(axi_awvalid),
        .axi_wdata(axi_wdata),
        .axi_wvalid(axi_wvalid),
        .axi_araddr(axi_araddr),
        .axi_arvalid(axi_arvalid),
        .axi_rdata(axi_rdata),
        .axi_rvalid(axi_rvalid),
        .predicted_class_out(predicted_class_out),
        .inference_done(inference_done)
    );

    logic [15:0] config_data;

    always #5 clk = ~clk;
    
    string cifar10_classes [0:15] = '{
        "AIRPLANE", "AUTOMOBILE", "BIRD", "CAT", "DEER",
        "DOG", "FROG", "HORSE", "SHIP", "TRUCK" , "LOCKED" , "LOCKED" , "LOCKED" , "LOCKED" , "LOCKED" , "LOCKED"};

    always_ff @(posedge clk) begin
        if (axi_rvalid && axi_araddr == 4'hF) begin
            if (axi_rdata[2:0] == 3'b100) begin
                $display("ASSERTION PASSED: FSM entered STATE_UNLOCKED (secure_mode_active == 1).");
            end else begin
                $display("ASSERTION FAILED: secure_mode_active not asserted — signature incorrect or AXI ID mismatch.");
            end
        end
    end

    initial begin
        clk = 0;
        resetn = 0;
        axi_awaddr  = 4'd0;
        axi_awvalid = 0;
        axi_wdata   = 32'd0;
        axi_wvalid  = 0;
        axi_araddr  = 4'd0;
        axi_arvalid = 0;
        #10 resetn = 1;

        // Compose Config Data
        // {bit15: inject_noise = 1}
        // {bit14-11: challenge = 4'b0101}
        // {bit10-7: sig_input = 4'b1000}
        // {bit6-5: axi_master_id = 2'b10}
        // {bit4: mode_select = 1}
        // {bit2-0: key_input[2:0] = 3'b0101} 
        config_data = {1'b1, 4'b0101, 4'b1000, 2'b10, 1'b1, 4'b1010};
        $display("Config Data Written:\n -> inject_noise=%b\n -> challenge=%b\n -> sig_input=%b\n -> axi_master_id=%b\n -> mode_select=%b\n -> key_input=%b",
                 config_data[15], config_data[14:11], config_data[10:7], config_data[6:5], config_data[4], config_data[3:0]);

        #20;
        axi_awaddr  <= 4'h0;
        axi_wdata   <= {16'd0, config_data};
        axi_awvalid <= 1;
        axi_wvalid  <= 1;
        #20;
        axi_awvalid <= 0;
        axi_wvalid  <= 0;

        #50;
        axi_araddr  <= 4'hF;
        axi_arvalid <= 1;
        #10;
        axi_arvalid <= 0;

        wait (inference_done);
        $display("TEST PASSED : CNN Inference completed.");
        $display("Predicted Class : %d", predicted_class_out);
        $display("Predicted Class Name : %s", cifar10_classes[predicted_class_out]);
        
        clk = 0;
        resetn = 0;
        axi_awaddr  = 4'd0;
        axi_awvalid = 0;
        axi_wdata   = 32'd0;
        axi_wvalid  = 0;
        axi_araddr  = 4'd0;
        axi_arvalid = 0;
        #10 resetn = 1;
        
        config_data = {1'b0, 4'b0101, 4'b1000, 2'b10, 1'b1, 4'b1010};
        $display("Config Data Written:\n -> inject_noise=%b\n -> challenge=%b\n -> sig_input=%b\n -> axi_master_id=%b\n -> mode_select=%b\n -> key_input=%b",
                 config_data[15], config_data[14:11], config_data[10:7], config_data[6:5], config_data[4], config_data[3:0]);

        
        #20;
        axi_awaddr  <= 4'h0;
        axi_wdata   <= {16'd0, config_data};
        axi_awvalid <= 1;
        axi_wvalid  <= 1;
        #20;
        axi_awvalid <= 0;
        axi_wvalid  <= 0;

        #50;
        axi_araddr  <= 4'hF;
        axi_arvalid <= 1;
        #10;
        axi_arvalid <= 0;
        
        wait (inference_done);
        $display("TEST PASSED : CNN Inference completed.");
        $display("Predicted Class : %d", predicted_class_out);
        $display("Predicted Class Name : %s", cifar10_classes[predicted_class_out]);
        
        #10 $finish;
    end

endmodule
