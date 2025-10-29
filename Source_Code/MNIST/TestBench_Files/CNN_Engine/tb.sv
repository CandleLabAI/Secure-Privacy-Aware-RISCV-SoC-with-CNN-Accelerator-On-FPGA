module CNN_Accelerator_Engine_tb;

    logic clk;
    logic resetn;
    logic start;
    logic [3:0] predicted_digit;
    logic done;
    logic pipeline;
    logic [4:0] input_image_index;

    initial clk = 0;
    always #5 clk = ~clk;  
    
    MNIST_CNN_Accelerator_Engine uut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .pipeline(pipeline),
        .input_image_index(input_image_index),
        .predicted_digit(predicted_digit),
        .done(done)
    );

    initial begin
       
        resetn = 0;
        start = 0;
        pipeline = 1;
        input_image_index = 1;
        #10;
        resetn = 1;
        
        #10;
        start = 1;

        #20;

        wait (done == 1);

        $display("Predicted Digit: %0d", predicted_digit);

        #10;
        $finish;
    end
endmodule
