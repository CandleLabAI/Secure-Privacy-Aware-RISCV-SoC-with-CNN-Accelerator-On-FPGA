`timescale 1ns / 1ps


module input_image_bram (
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


module conv2d_64ch_output_bram (
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


module dense_128_bram (
    input  logic [31:0]  BRAM_PORTA_0_addr, input  logic BRAM_PORTA_0_clk,
    input  logic [127:0] BRAM_PORTA_0_din,  output logic [127:0] BRAM_PORTA_0_dout,
    input  logic BRAM_PORTA_0_en,           input  logic [15:0]  BRAM_PORTA_0_we,
    input  logic [31:0]  BRAM_PORTB_0_addr, input  logic BRAM_PORTB_0_clk,
    input  logic [127:0] BRAM_PORTB_0_din,  output logic [127:0] BRAM_PORTB_0_dout,
    input  logic BRAM_PORTB_0_en,           input  logic [15:0]  BRAM_PORTB_0_we
);
    bram_tdp_be #(.DATA_WIDTH(128), .ADDR_WIDTH(6), .WE_WIDTH(16)) core (
        .clka(BRAM_PORTA_0_clk), .ena(BRAM_PORTA_0_en), .wea(BRAM_PORTA_0_we),
        .addra(BRAM_PORTA_0_addr[5:0]), .dina(BRAM_PORTA_0_din), .douta(BRAM_PORTA_0_dout),
        .clkb(BRAM_PORTB_0_clk), .enb(BRAM_PORTB_0_en), .web(BRAM_PORTB_0_we),
        .addrb(BRAM_PORTB_0_addr[5:0]), .dinb(BRAM_PORTB_0_din), .doutb(BRAM_PORTB_0_dout)
    );
endmodule


module max_pool_output_bram (
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


module dense_weights_rom_block0 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block0.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block1 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block1.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block2 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block2.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block3 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block3.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block4 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block4.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block5 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block5.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block6 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block6.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule
module dense_weights_rom_block7 (input logic clk, input logic [14:0] addr, output logic signed [7:0] data);
    rom_generic #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .INIT_FILE("dense1_weights_block7.hex")) core (.clk(clk), .addr(addr), .dout(data));
endmodule

