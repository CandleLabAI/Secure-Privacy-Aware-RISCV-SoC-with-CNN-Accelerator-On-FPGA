`timescale 1ns / 1ps


package forwarding;
    typedef struct packed {
        logic        data_valid;
        logic [31:0] data;
        logic  [4:0] address;
    } t;
endpackage


