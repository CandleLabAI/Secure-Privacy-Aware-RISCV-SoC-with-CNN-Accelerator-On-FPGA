module dense_128_bram_wrapper
   (BRAM_PORTA_0_addr,
    BRAM_PORTA_0_clk,
    BRAM_PORTA_0_din,
    BRAM_PORTA_0_dout,
    BRAM_PORTA_0_en,
    BRAM_PORTA_0_we,
    BRAM_PORTB_0_addr,
    BRAM_PORTB_0_clk,
    BRAM_PORTB_0_din,
    BRAM_PORTB_0_dout,
    BRAM_PORTB_0_en,
    BRAM_PORTB_0_we);
  input [31:0]BRAM_PORTA_0_addr;
  input BRAM_PORTA_0_clk;
  input [127:0]BRAM_PORTA_0_din;
  output [127:0]BRAM_PORTA_0_dout;
  input BRAM_PORTA_0_en;
  input [15:0]BRAM_PORTA_0_we;
  input [31:0]BRAM_PORTB_0_addr;
  input BRAM_PORTB_0_clk;
  input [127:0]BRAM_PORTB_0_din;
  output [127:0]BRAM_PORTB_0_dout;
  input BRAM_PORTB_0_en;
  input [15:0]BRAM_PORTB_0_we;

  wire [31:0]BRAM_PORTA_0_addr;
  wire BRAM_PORTA_0_clk;
  wire [127:0]BRAM_PORTA_0_din;
  wire [127:0]BRAM_PORTA_0_dout;
  wire BRAM_PORTA_0_en;
  wire [15:0]BRAM_PORTA_0_we;
  wire [31:0]BRAM_PORTB_0_addr;
  wire BRAM_PORTB_0_clk;
  wire [127:0]BRAM_PORTB_0_din;
  wire [127:0]BRAM_PORTB_0_dout;
  wire BRAM_PORTB_0_en;
  wire [15:0]BRAM_PORTB_0_we;

  dense_128_bram dense_128_bram_i
       (.BRAM_PORTA_0_addr(BRAM_PORTA_0_addr),
        .BRAM_PORTA_0_clk(BRAM_PORTA_0_clk),
        .BRAM_PORTA_0_din(BRAM_PORTA_0_din),
        .BRAM_PORTA_0_dout(BRAM_PORTA_0_dout),
        .BRAM_PORTA_0_en(BRAM_PORTA_0_en),
        .BRAM_PORTA_0_we(BRAM_PORTA_0_we),
        .BRAM_PORTB_0_addr(BRAM_PORTB_0_addr),
        .BRAM_PORTB_0_clk(BRAM_PORTB_0_clk),
        .BRAM_PORTB_0_din(BRAM_PORTB_0_din),
        .BRAM_PORTB_0_dout(BRAM_PORTB_0_dout),
        .BRAM_PORTB_0_en(BRAM_PORTB_0_en),
        .BRAM_PORTB_0_we(BRAM_PORTB_0_we));
endmodule
