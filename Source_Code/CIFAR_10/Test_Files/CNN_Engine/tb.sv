module CIFAR_CNN_Accelerator_Engine_tb;

    logic clk;
    logic resetn;
    logic start;
    logic [3:0] predicted_class;
    logic done;

    initial clk = 0;
    always #5 clk = ~clk;  
    
    CIFAR_10_CNN_Accelerator_Engine uut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .predicted_class(predicted_class),
        .done(done)
    );

    
    string cifar10_classes [0:9] = '{
        "AIRPLANE", "AUTOMOBILE", "BIRD", "CAT", "DEER",
        "DOG", "FROG", "HORSE", "SHIP", "TRUCK"};

    initial begin
        resetn = 0;
        start = 0;

        #10;
        resetn = 1;
        
        #10;
        start = 1;
        #10;
        start = 0;

        #20;

        wait (done == 1);

        $display("Predicted Class Index: %0d", predicted_class);
        $display("Predicted Class Name : %s", cifar10_classes[predicted_class]);

        #10;
        $finish;
    end
endmodule
