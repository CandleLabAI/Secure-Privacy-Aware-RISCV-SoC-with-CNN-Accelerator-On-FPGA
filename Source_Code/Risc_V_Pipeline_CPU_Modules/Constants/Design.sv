

`timescale 1ns / 1ps


package constants;


    localparam bit [31:0] MEMORY_START = 32'h0001_0000;
    localparam bit [31:0] MEMORY_SIZE  = 32'h0000_2000;

    localparam bit [31:0] LEDS_START = 32'h0008_0000;
    localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

    localparam bit [31:0] BUTTONS_START = 32'h0008_1000;
    localparam bit [31:0] BUTTONS_SIZE  = 32'h0000_0001;

    localparam bit [31:0] SWITCHES_START = 32'h0008_2000;
    localparam bit [31:0] SWITCHES_SIZE  = 32'h0000_0001;

    localparam bit [31:0] SEGMENTS_START = 32'h0008_3000;
    localparam bit [31:0] SEGMENTS_SIZE  = 32'h0000_0001;

    localparam bit [31:0] UART_START = 32'h0008_4000;
    localparam bit [31:0] UART_SIZE  = 32'h0000_0001;

    localparam bit [31:0] TIMER_START = 32'h0008_5000;
    localparam bit [31:0] TIMER_SIZE  = 32'h0000_0005;

    localparam bit [31:0] VGA_START = 32'h0009_0000;
    localparam bit [31:0] VGA_SIZE  = 32'h0000_9600;

    localparam bit [31:0] TEST_START = 32'h0012_0000;
    localparam bit [31:0] TEST_SIZE  = 32'h0000_0005;


    localparam bit [31:0] RESET_ADDRESS = 32'h0000_0000;


    localparam bit [31:0] NOP = 32'h00000013;

endpackage


