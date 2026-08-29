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


    string cifar10_classes [0:9];
    initial begin
        cifar10_classes[0] = "AIRPLANE";
        cifar10_classes[1] = "AUTOMOBILE";
        cifar10_classes[2] = "BIRD";
        cifar10_classes[3] = "CAT";
        cifar10_classes[4] = "DEER";
        cifar10_classes[5] = "DOG";
        cifar10_classes[6] = "FROG";
        cifar10_classes[7] = "HORSE";
        cifar10_classes[8] = "SHIP";
        cifar10_classes[9] = "TRUCK";
    end

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

