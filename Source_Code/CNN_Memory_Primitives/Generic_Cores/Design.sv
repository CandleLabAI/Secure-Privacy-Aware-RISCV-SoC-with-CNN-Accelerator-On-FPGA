`timescale 1ns / 1ps


module bram_tdp_be #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 13,
    parameter int WE_WIDTH   = DATA_WIDTH/8
) (
    input  logic                    clka,
    input  logic                    ena,
    input  logic [WE_WIDTH-1:0]     wea,
    input  logic [ADDR_WIDTH-1:0]   addra,
    input  logic [DATA_WIDTH-1:0]   dina,
    output logic [DATA_WIDTH-1:0]   douta,

    input  logic                    clkb,
    input  logic                    enb,
    input  logic [WE_WIDTH-1:0]     web,
    input  logic [ADDR_WIDTH-1:0]   addrb,
    input  logic [DATA_WIDTH-1:0]   dinb,
    output logic [DATA_WIDTH-1:0]   doutb
);

    localparam int DEPTH   = (1 << ADDR_WIDTH);
    localparam int BYTES   = DATA_WIDTH/8;

    (* ram_style = "block" *) logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = '0;
    end

    // Port A: write-first synchronous read/write
    always_ff @(posedge clka) begin
        if (ena) begin
            for (i = 0; i < BYTES; i = i + 1)
                if (wea[i]) mem[addra][i*8 +: 8] <= dina[i*8 +: 8];
            douta <= mem[addra];
        end
    end

    // Port B: write-first synchronous read/write
    always_ff @(posedge clkb) begin
        if (enb) begin
            for (i = 0; i < BYTES; i = i + 1)
                if (web[i]) mem[addrb][i*8 +: 8] <= dinb[i*8 +: 8];
            doutb <= mem[addrb];
        end
    end

endmodule


module rom_generic #(
    parameter int    DATA_WIDTH = 8,
    parameter int    ADDR_WIDTH = 15,
    parameter        INIT_FILE  = ""
) (
    input  logic                   clk,
    input  logic [ADDR_WIDTH-1:0]  addr,
    output logic [DATA_WIDTH-1:0]  dout
);

    localparam int DEPTH = (1 << ADDR_WIDTH);

    (* rom_style = "block" *) logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = '0;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    always_ff @(posedge clk) begin
        dout <= mem[addr];
    end

endmodule


module processing_element (
    input  signed [7:0]  a,
    input  signed [7:0]  b,
    output signed [15:0] result
);
    assign result = a * b;
endmodule

