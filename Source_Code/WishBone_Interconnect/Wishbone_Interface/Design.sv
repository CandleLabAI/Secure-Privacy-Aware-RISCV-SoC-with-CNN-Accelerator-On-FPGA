`timescale 1ns / 1ps


interface wishbone_interface #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);

    logic                     cyc;
    logic                     stb;
    logic                     we;
    logic [ADDR_WIDTH-1:0]    adr;
    logic [DATA_WIDTH-1:0]    dat_mosi;
    logic [DATA_WIDTH-1:0]    dat_miso;
    logic [DATA_WIDTH/8-1:0]  sel;
    logic                     ack;
    logic                     err;

    modport master (
        output cyc, stb, we, adr, dat_mosi, sel,
        input  dat_miso, ack, err
    );

    modport slave (
        input  cyc, stb, we, adr, dat_mosi, sel,
        output dat_miso, ack, err
    );

endinterface

