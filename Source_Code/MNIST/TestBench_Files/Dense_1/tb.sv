module dense_layer_1600_to_128_tb;
    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;
    wire [31:0] read_data;
    wire done;

    dense_layer_1600_to_128 uut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .read_addr(read_addr),
        .read_data(read_data),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("Starting dense_2_layer testbench");

        resetn = 0;
        start = 0;
        read_addr = 0;

        #20;
        resetn = 1;

        #10;
        start = 1;
        #10;
        start = 0;

        wait(done);

        $display("Computation done. Reading 128 output values:");

        repeat (128) begin
            #10;
            $display("read_addr = %0d, read_data = %0d", read_addr, $signed(read_data));
            read_addr = read_addr + 1;
        end

        $display("Testbench finished");
        $finish;
    end

endmodule
