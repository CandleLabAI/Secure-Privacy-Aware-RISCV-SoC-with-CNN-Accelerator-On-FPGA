module conv2d_3x3_engine_32ch_tb;

    reg clk;
    reg resetn;
    reg start;
    reg [31:0] read_addr;
    wire [7:0] read_data;
    wire done;

    conv2d_3x3_engine_32ch uut (
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

    integer i=0;
    

    initial begin
        $display("Starting Testbench...");

        resetn = 0; start = 0; read_addr = 0;
        #50;
        resetn = 1;
        #50;
        start = 1;
        #10;
        start = 0;

        wait(done == 1);
        #50;
        for (i = 0; i < 21632; i = i + 1) begin
            read_addr = i;
            #10;
            $display("AADR %0d  :  DATA  %0h",read_addr, read_data);
        end
        $finish;
    end

endmodule
