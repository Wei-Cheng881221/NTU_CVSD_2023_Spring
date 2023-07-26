// FSM State
`ifndef DEFINE_V
`define DEFINE_V

    `define State_IDLE 0
    `define State_LOAD 1
    `define State_PROC 2
    `define State_OUT  3

    // OP code
    `define OP_MAX     1
    `define OP_MIN     2
    `define OP_T2MAX   3
    `define OP_L2MIN   4
    `define OP_AVG     5
    `define OP_EXTRACT 6
    `define OP_EXCLUDE 7
    `define OP_PMAX    8
    `define OP_PMIN    9

    // Extract boundary
    `define EXTRACT_LOW  128'h6FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    `define EXTRACT_HIGH 128'hAFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF

    //Exclude boundry
    `define EXCLUDE_LOW  128'h7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    `define EXCLUDE_HIGH 128'hBFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF

`endif