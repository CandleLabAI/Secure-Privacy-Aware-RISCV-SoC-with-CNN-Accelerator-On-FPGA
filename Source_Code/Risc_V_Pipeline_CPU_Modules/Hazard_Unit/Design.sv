module hazard_unit (
    input  logic [4:0] rs1,
    input  logic [4:0] rs2,

    input  logic exe_valid,
    input  logic [4:0] exe_rd,

    input  logic mem_valid,
    input  logic [4:0] mem_rd,

    input  logic wb_valid,
    input  logic [4:0] wb_rd,
    input logic stall_in,

    output logic stall
);

    logic hazard_rs1, hazard_rs2;

    assign hazard_rs1 = (rs1 != 0) && (
                            (exe_valid && rs1 == exe_rd) ||
                            (mem_valid && rs1 == mem_rd) ||
                            (wb_valid  && rs1 == wb_rd)
                        );

    assign hazard_rs2 = (rs2 != 0) && (
                            (exe_valid && rs2 == exe_rd) ||
                            (mem_valid && rs2 == mem_rd) ||
                            (wb_valid  && rs2 == wb_rd)
                        );

    assign stall = hazard_rs1 || hazard_rs2 || stall_in ;

endmodule
