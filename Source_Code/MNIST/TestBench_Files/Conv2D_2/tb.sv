module conv2d_13_13_32_to_11_11_64_tb;
    reg clk;
    reg resetn;
    reg start;
    wire done;
    reg  [31:0] read_addr;
    wire [7:0]  read_data;

    conv2d_13_13_32_to_11_11_64 uut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .read_addr(read_addr),
        .read_data(read_data),
        .done(done)
    );

    always #5 clk = ~clk;

    integer i=0;

    initial begin
        $display("---- Starting Testbench ----");

        clk = 0;
        resetn = 0;
        start = 0;
        read_addr = 0;
        #20;
        resetn = 1;

        #10;
        start = 1;
        #10;
        start = 0;

        wait (done == 1);

        for (i = 1; i < 7745; i = i + 1) begin
            read_addr = i;
            #10;
            $display("ADDR %0d : DATA  %0h",read_addr-1, read_data);
        end
        #20;
        $finish;
    end

endmodule
