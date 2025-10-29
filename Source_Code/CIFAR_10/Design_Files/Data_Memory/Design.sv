module data_memory #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    mode,         
    input  wire [5:0]              layer_select, 
    input  wire [17:0]             addr,     
    output reg  [DATA_WIDTH-1:0]   data_out
);

    localparam L_MNIST_CONV1_W   = 6'd0;
    localparam L_MNIST_CONV1_B   = 6'd1;
    localparam L_MNIST_CONV2_W   = 6'd2;
    localparam L_MNIST_CONV2_B   = 6'd3;
    localparam L_MNIST_FC1_W     = 6'd4;
    localparam L_MNIST_FC1_B     = 6'd5;
    localparam L_MNIST_FC2_W     = 6'd6;
    localparam L_MNIST_FC2_B     = 6'd7;

    localparam L_CIFAR_C1_W      = 6'd16;
    localparam L_CIFAR_C1_B      = 6'd17;
    localparam L_CIFAR_C1_BN_G   = 6'd18;
    localparam L_CIFAR_C1_BN_B   = 6'd19;
    localparam L_CIFAR_C1_BN_M   = 6'd20;
    localparam L_CIFAR_C1_BN_V   = 6'd21;
    localparam L_CIFAR_C2_W      = 6'd22;
    localparam L_CIFAR_C2_B      = 6'd23;
    localparam L_CIFAR_C2_BN_G   = 6'd24;
    localparam L_CIFAR_C2_BN_B   = 6'd25;
    localparam L_CIFAR_C2_BN_M   = 6'd26;
    localparam L_CIFAR_C2_BN_V   = 6'd27;
    localparam L_CIFAR_C3_W      = 6'd28;
    localparam L_CIFAR_C3_B      = 6'd29;
    localparam L_CIFAR_C3_BN_G   = 6'd30;
    localparam L_CIFAR_C3_BN_B   = 6'd31;
    localparam L_CIFAR_C3_BN_M   = 6'd32;
    localparam L_CIFAR_C3_BN_V   = 6'd33;
    localparam L_CIFAR_C4_W      = 6'd34;
    localparam L_CIFAR_C4_B      = 6'd35;
    localparam L_CIFAR_C4_BN_G   = 6'd36;
    localparam L_CIFAR_C4_BN_B   = 6'd37;
    localparam L_CIFAR_C4_BN_M   = 6'd38;
    localparam L_CIFAR_C4_BN_V   = 6'd39;
    localparam L_CIFAR_C5_W      = 6'd40;
    localparam L_CIFAR_C5_B      = 6'd41;
    localparam L_CIFAR_C5_BN_G   = 6'd42;
    localparam L_CIFAR_C5_BN_B   = 6'd43;
    localparam L_CIFAR_C5_BN_M   = 6'd44;
    localparam L_CIFAR_C5_BN_V   = 6'd45;
    localparam L_CIFAR_C6_W      = 6'd46;
    localparam L_CIFAR_C6_B      = 6'd47;
    localparam L_CIFAR_C6_BN_G   = 6'd48;
    localparam L_CIFAR_C6_BN_B   = 6'd49;
    localparam L_CIFAR_C6_BN_M   = 6'd50;
    localparam L_CIFAR_C6_BN_V   = 6'd51;
    localparam L_CIFAR_FC1_W     = 6'd52;
    localparam L_CIFAR_FC1_B     = 6'd53;
    localparam L_CIFAR_FC1_BN_G  = 6'd54;
    localparam L_CIFAR_FC1_BN_B  = 6'd55;
    localparam L_CIFAR_FC1_BN_M  = 6'd56;
    localparam L_CIFAR_FC1_BN_V  = 6'd57;
    localparam L_CIFAR_FC2_W     = 6'd58;
    localparam L_CIFAR_FC2_B     = 6'd59;

    wire [DATA_WIDTH-1:0] rom_out [0:63];

    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(9))  rom_mn_c1_w ( .clk(clk), .addr(addr[8:0]),   .dout(rom_out[L_MNIST_CONV1_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_mn_c1_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_MNIST_CONV1_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(15)) rom_mn_c2_w ( .clk(clk), .addr(addr[14:0]),  .dout(rom_out[L_MNIST_CONV2_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(6))  rom_mn_c2_b ( .clk(clk), .addr(addr[5:0]),   .dout(rom_out[L_MNIST_CONV2_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(18)) rom_mn_fc1_w( .clk(clk), .addr(addr[17:0]),  .dout(rom_out[L_MNIST_FC1_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_mn_fc1_b( .clk(clk), .addr(addr[6:0]),   .dout(rom_out[L_MNIST_FC1_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(11)) rom_mn_fc2_w( .clk(clk), .addr(addr[10:0]),  .dout(rom_out[L_MNIST_FC2_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(4))  rom_mn_fc2_b( .clk(clk), .addr(addr[3:0]),   .dout(rom_out[L_MNIST_FC2_B]));

    // Conv1
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c1_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C1_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c1_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C1_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c1_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C1_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c1_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C1_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c1_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C1_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c1_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C1_BN_V]));

    // Conv2
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c2_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C2_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c2_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C2_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c2_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C2_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c2_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C2_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c2_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C2_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c2_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C2_BN_V]));

    // Conv3
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c3_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C3_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c3_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C3_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c3_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C3_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c3_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C3_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c3_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C3_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c3_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C3_BN_V]));

    // Conv4
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c4_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C4_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c4_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C4_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c4_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C4_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c4_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C4_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c4_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C4_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c4_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C4_BN_V]));

    // Conv5
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c5_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C5_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c5_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C5_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c5_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C5_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c5_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C5_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c5_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C5_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c5_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C5_BN_V]));

    // Conv6
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(10)) rom_cf_c6_w ( .clk(clk), .addr(addr[9:0]),   .dout(rom_out[L_CIFAR_C6_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c6_b ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C6_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c6_g ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C6_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c6_be( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C6_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c6_m ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C6_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(5))  rom_cf_c6_v ( .clk(clk), .addr(addr[4:0]),   .dout(rom_out[L_CIFAR_C6_BN_V]));

    // FC1
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(18)) rom_cf_fc1_w( .clk(clk), .addr(addr[17:0]),  .dout(rom_out[L_CIFAR_FC1_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_cf_fc1_b( .clk(clk), .addr(addr[6:0]),   .dout(rom_out[L_CIFAR_FC1_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_cf_fc1_g( .clk(clk), .addr(addr[6:0]),   .dout(rom_out[L_CIFAR_FC1_BN_G]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_cf_fc1_be( .clk(clk), .addr(addr[6:0]),  .dout(rom_out[L_CIFAR_FC1_BN_B]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_cf_fc1_m( .clk(clk), .addr(addr[6:0]),   .dout(rom_out[L_CIFAR_FC1_BN_M]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(7))  rom_cf_fc1_v( .clk(clk), .addr(addr[6:0]),   .dout(rom_out[L_CIFAR_FC1_BN_V]));

    // FC2
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(11)) rom_cf_fc2_w( .clk(clk), .addr(addr[10:0]),  .dout(rom_out[L_CIFAR_FC2_W]));
    rom_generic #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(4))  rom_cf_fc2_b( .clk(clk), .addr(addr[3:0]),   .dout(rom_out[L_CIFAR_FC2_B]));

    always @(*) begin
        data_out = rom_out[layer_select];
    end

endmodule
