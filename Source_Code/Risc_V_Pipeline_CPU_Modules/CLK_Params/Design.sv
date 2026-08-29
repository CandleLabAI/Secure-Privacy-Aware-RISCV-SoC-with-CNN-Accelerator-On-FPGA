

`timescale 1ns / 1ps


package clk_params;


    localparam real INPUT_CLK_FREQUENCY_MHZ    =  100.000;
    localparam real INPUT_CLK_JITTER_PS        =   95.000;
    localparam real INPUT_CLK_JITTER_TO_PERIOD =    0.010;
    localparam real INPUT_CLK_PERIOD_NS        = 1000.000 / INPUT_CLK_FREQUENCY_MHZ;


    localparam real MMCM_MUL   = 10.000;
    localparam int  MMCM_DIV   = 1;
    localparam real MMCM_DIV_0 = 20.000;

    localparam real SYS_CLK_FREQUENCY_MHZ = (INPUT_CLK_FREQUENCY_MHZ / MMCM_DIV * MMCM_MUL) / MMCM_DIV_0;
    localparam real SYS_CLK_PERIOD_NS     = 1000.000 / SYS_CLK_FREQUENCY_MHZ;


    localparam int  PLL1_MUL   = 53;
    localparam int  PLL1_DIV   = 5;
    localparam real PLL1_DIV_0 = 10;

    localparam real PLL1_FREQUENCY_MHZ = (INPUT_CLK_FREQUENCY_MHZ / PLL1_DIV * PLL1_MUL) / PLL1_DIV_0;
    localparam real PLL1_PERIOD_NS     = 1000.000 / PLL1_FREQUENCY_MHZ;


    localparam int  PLL2_MUL   = 19;
    localparam int  PLL2_DIV   = 2;
    localparam real PLL2_DIV_0 = 40;

    localparam real PLL2_FREQUENCY_MHZ = (PLL1_FREQUENCY_MHZ / PLL2_DIV * PLL2_MUL) / PLL2_DIV_0;
    localparam real PLL2_PERIOD_NS     = 1000.000 / PLL2_FREQUENCY_MHZ;


    localparam real VGA_CLK_FREQUENCY_MHZ = PLL2_FREQUENCY_MHZ;
    localparam real VGA_CLK_PERIOD_NS     = PLL2_PERIOD_NS;


    localparam int  SIM_CYCLES_PER_SYS_CLK = int'(SYS_CLK_PERIOD_NS);
    localparam int  SIM_CYCLES_PER_VGA_CLK = int'(VGA_CLK_PERIOD_NS);

endpackage


