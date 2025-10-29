module maxpool2d_2x2_stride2_32ch_tb;

    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;
    wire [7:0] read_data;
    wire done;

    maxpool2d_2x2_stride2_32ch dut (
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
        #20;

        start = 1;
        #10;
        start = 0;
        wait(done);
        #10;

        $display("=== MaxPool Output ===");
        for (i = 0; i < 5408; i = i + 1) begin
            read_addr = i;
            #10;
            $display("Address %0d : Data = %0h", i, read_data);
        end
        $finish;
    end

endmodule
