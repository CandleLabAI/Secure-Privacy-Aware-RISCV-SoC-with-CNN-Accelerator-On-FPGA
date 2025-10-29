module dense_layer_128_to_10_tb;

    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;
    wire [63:0] read_data;
    wire done;

    dense_layer_128_to_10 dut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .read_addr(read_addr),
        .read_data(read_data),
        .done(done)
    );
    
    always #5 clk = ~clk;
    integer i=0;

    task read_all_outputs;
        begin
            for (i = 0; i < 10; i = i + 1) begin
                read_addr = i * 16;
                #20; 
                $display("Output[%0d] = %0d", i, $signed(read_data));
            end
        end
    endtask

    initial begin
        $display("---- Starting Simulation ----");
        clk = 0;
        resetn = 0;
        start = 0;
        read_addr = 0;

        #20 resetn = 1;
        #20 start = 1;
        #10 start = 0;

        wait(done == 1);
        #10;

        read_all_outputs();

        $display("---- Simulation Done ----");
        $finish;
    end

endmodule
