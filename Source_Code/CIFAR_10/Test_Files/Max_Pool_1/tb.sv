module maxpool2d_2x2_stride2_1x_32ch_tb;

    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;

    wire [3:0] read_data;
    wire done;

    maxpool2d_2x2_stride2_1x_32ch uut (
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

        wait(done == 1);
        #50;

        for (i = 0; i < 8192; i = i + 1) begin
            read_addr = i;
            #10;
            $display("Output[%0d] = %0d", i, $signed(read_data));
        end

        $display("All data read successfully.");
        $finish;
    end

endmodule
