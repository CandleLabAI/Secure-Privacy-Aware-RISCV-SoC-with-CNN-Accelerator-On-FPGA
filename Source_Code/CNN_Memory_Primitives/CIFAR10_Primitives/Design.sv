`timescale 1ns / 1ps


module input_output_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(13), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[12:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[12:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module second_order_conv_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(12), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[11:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[11:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module third_order_conv_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(11), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[10:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[10:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module max_pool_1_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(11), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[10:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[10:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module max_pool_2_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(10), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[9:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[9:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module max_pool_3_bram (
    input  logic [31:0] BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [31:0] BRAM_PORTA_0_din,  output logic [31:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,          input  logic [3:0]  BRAM_PORTA_0_we,
    input  logic [31:0] BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [31:0] BRAM_PORTB_0_din,  output logic [31:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,          input  logic [3:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(32), .ADDR_WIDTH(9), .WE_WIDTH(4)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[8:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[8:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module cifar10_dense_weights_rom_block0 (
    input  logic [17:0] addr,
    output logic signed [7:0] data
);
    localparam int DEPTH = (1 << 18);
    (* rom_style = "distributed" *) logic signed [7:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'sd0;
        $readmemh("cifar10_dense1_weights.hex", mem);
    end

    assign data = mem[addr];
endmodule

