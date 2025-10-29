module Top_SOC_Module_tb;
    logic clk;
    logic rst;
    logic pipeline;
    logic [6:0] switches;
    logic [6:0] leds;
    logic       done;

    Top_SOC_Module dut (
        .clk(clk),
        .rst(rst),
        .pipeline(pipeline),
        .switches(switches),
        .leds(leds),
        .done(done)
    );

  
    initial clk = 0;
    always #10 clk = ~clk;
    integer j=0;
    
    string cifar10_classes [0:15] = '{
        "AIRPLANE", "AUTOMOBILE", "BIRD", "CAT", "DEER",
        "DOG", "FROG", "HORSE", "SHIP", "TRUCK",
        "LOCKED", "LOCKED", "LOCKED", "LOCKED", "LOCKED", "LOCKED"
    };

    initial begin
        rst = 1;
        pipeline = 1;
        switches = 7'b0100000;
        #100;
        rst = 0;
        #12000; 
        wait (done);
        #1000;

        $display("\n--- Mode 01: TASK ---");
        for (int i = 5; i < 24; i=i+4) begin
            switches = 7'b0100000 | i;  
            #20;
            $display("INDEX : %0d | CLASS ID : 0x%02h | [LED-CNN] Predicted Class Name : %s", j, leds,cifar10_classes[leds]);
            j=j+1;
        end
         $display("\n--- Mode 01: TASK DONE ---");
        
        #10 $finish;
    end
    
endmodule
