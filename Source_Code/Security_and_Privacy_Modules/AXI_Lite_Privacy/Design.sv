`timescale 1ns / 1ps


module axi_lite_privacy (
    input  logic        clk,
    input  logic        resetn,

    // AXI4-Lite-style write channel (simplified: address+data captured together)
    input  logic [3:0]  axi_awaddr,
    input  logic         axi_awvalid,
    input  logic [31:0] axi_wdata,
    input  logic         axi_wvalid,

    // AXI4-Lite-style read channel
    input  logic [3:0]  axi_araddr,
    input  logic         axi_arvalid,
    output logic [31:0] axi_rdata,
    output logic         axi_rvalid,

    // Decoded fields driving the signature verifier / secure FSM / noise injector
    output logic [3:0]  key_input,
    output logic         mode_select,
    output logic [1:0]  axi_master_id,
    output logic [3:0]  sig_input,
    output logic [3:0]  challenge,
    output logic         inject_noise,
    output logic         write_enable,

    // Status inputs read back at ADDR_STATUS
    input  logic         fsm_locked,
    input  logic         fsm_error,
    input  logic         secure_mode_active
);

    localparam logic [3:0] ADDR_CTRL   = 4'h0;
    localparam logic [3:0] ADDR_STATUS = 4'hF;

    // Write side: latch the authentication payload and pulse write_enable
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            key_input     <= 4'd0;
            mode_select   <= 1'b0;
            axi_master_id <= 2'd0;
            sig_input     <= 4'd0;
            challenge     <= 4'd0;
            inject_noise  <= 1'b0;
            write_enable  <= 1'b0;
        end else begin
            write_enable <= 1'b0;
            if (axi_awvalid && axi_wvalid && axi_awaddr == ADDR_CTRL) begin
                key_input     <= axi_wdata[3:0];
                mode_select   <= axi_wdata[4];
                axi_master_id <= axi_wdata[6:5];
                sig_input     <= axi_wdata[10:7];
                challenge     <= axi_wdata[14:11];
                inject_noise  <= axi_wdata[15];
                write_enable  <= 1'b1;
            end
        end
    end

    // Read side: single-cycle latency status read
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            axi_rdata  <= 32'd0;
            axi_rvalid <= 1'b0;
        end else begin
            axi_rvalid <= 1'b0;
            if (axi_arvalid) begin
                case (axi_araddr)
                    ADDR_STATUS: axi_rdata <= {29'd0, secure_mode_active, fsm_locked, fsm_error};
                    default:     axi_rdata <= 32'd0;
                endcase
                axi_rvalid <= 1'b1;
            end
        end
    end

endmodule

