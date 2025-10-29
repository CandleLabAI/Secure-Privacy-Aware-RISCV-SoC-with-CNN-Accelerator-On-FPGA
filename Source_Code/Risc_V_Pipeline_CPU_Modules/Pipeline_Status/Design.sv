`timescale 1ns / 1ps

package pipeline_status;
    typedef enum logic [3:0] {
        VALID,
        BUBBLE,
        FETCH_MISALIGNED,
        FETCH_FAULT,
        ILLEGAL_INSTRUCTION,
        LOAD_MISALIGNED,
        LOAD_FAULT,
        STORE_MISALIGNED,
        STORE_FAULT,
        ECALL, // TODO: is this a state?
        EBREAK // TODO: is this a state?
    } forwards_t;

    typedef enum logic [1:0] {
        READY,
        STALL,
        JUMP
    } backwards_t;
endpackage
