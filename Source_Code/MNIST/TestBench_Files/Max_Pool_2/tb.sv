module maxpool2d_2x2_stride2_64ch_flatten_tb;

    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;
    wire [7:0] read_data;
    wire done;

    maxpool2d_2x2_stride2_64ch_flatten uut (
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
        $display("Starting maxpool2d_2x2_stride2_64ch testbench");

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
        $display("Maxpooling done. Reading BRAM contents:");

        repeat (1600) begin
            #10;
            $display("read_addr = %0d, read_data = %0h", read_addr, read_data);
            read_addr = read_addr + 1;
        end

        $display("Testbench finished");
        $finish;
    end

endmodule
