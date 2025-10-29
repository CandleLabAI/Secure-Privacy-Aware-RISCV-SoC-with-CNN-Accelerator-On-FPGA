module register (
    input  logic        clk,
    input  logic        rst, 

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    input  logic        rd_write_enable,
    input  logic [4:0]  rd,
    input  logic [31:0] rd_data,

    input  logic        dump_all_regs
);

    logic [31:0] regs[31:0];

    assign rs1_data = (!$isunknown(rs1)) ? ((rs1 == 5'd0) ? 32'd0 : regs[rs1]) : 32'd0;
    assign rs2_data = (!$isunknown(rs2)) ? ((rs2 == 5'd0) ? 32'd0 : regs[rs2]) : 32'd0;

     //ABI name lookup
//    function string reg_abi(input int idx);
//        case (idx)
//            0:  return "zero";  1:  return "ra";   2:  return "sp";   3:  return "gp";
//            4:  return "tp";    5:  return "t0";   6:  return "t1";   7:  return "t2";
//            8:  return "s0";    9:  return "s1";  10: return "a0";  11: return "a1";
//            12: return "a2";   13: return "a3";  14: return "a4";  15: return "a5";
//            16: return "a6";   17: return "a7";  18: return "s2";  19: return "s3";
//            20: return "s4";   21: return "s5";  22: return "s6";  23: return "s7";
//            24: return "s8";   25: return "s9";  26: return "s10"; 27: return "s11";
//            28: return "t3";   29: return "t4";  30: return "t5";  31: return "t6";
//            default: return "x?";
//        endcase
//    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 32'd0;
            end
        end else if (rd_write_enable && rd != 5'd0) begin
            regs[rd] <= rd_data;
        end
    end

    logic dump_trigger_d;

    always_ff @(posedge clk) begin
        dump_trigger_d <= dump_all_regs;

        if (dump_trigger_d) begin
            $display("========== [REGISTERS] ==========");
            for (int i = 0; i < 32; i++) begin
//                $display("x%0d (%s) = 0x%08h", i, reg_abi(i), regs[i]);
                $display("x%0d = 0x%08h", i, regs[i]);
            end
        end
    end

endmodule
