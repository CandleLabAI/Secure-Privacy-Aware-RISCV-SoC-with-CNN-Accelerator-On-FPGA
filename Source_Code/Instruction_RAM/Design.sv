module wishbone_ram #(
    parameter logic [31:0] ADDRESS = 32'h00000000,
    parameter logic [31:0] SIZE    = 1024 
)(
    input  logic clk,
    input  logic rst,
    input  logic [1:0] mode, 
    wishbone_interface.slave port_a
);

    localparam int WORD_COUNT = SIZE / 4;

    logic [31:0] mem_init           [0:WORD_COUNT-1];

    logic [$clog2(WORD_COUNT)-1:0] idx_a;
    logic [31:0] selected_word;
    logic ack_a_pending;
    integer instruc=0;

    initial begin
        $readmemh("cnn.mem ",mem_init);

        for (int i = 0; i < WORD_COUNT; i++) begin
            if (mem_init[i]           === 32'bx) mem_init[i]           = 32'h00000013;
        end
    end
    
    always_comb begin
        case (mode)
            2'b01: for (int i = 0; i < 21; i++) begin
            if (mem_init[i]==32'h00000013) begin instruc=instruc+1; end
            else $display("[INIT/CNN] mem[%0d] = %h", i-instruc, mem_init[i]); end
            default:;
        endcase
    end

    always_comb begin
        case (mode)
            2'b01: selected_word = mem_init[idx_a];
            default: selected_word = 32'h00000013; 
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            port_a.ack      <= 0;
            port_a.dat_miso <= 0;
            ack_a_pending   <= 0;
        end else begin
            port_a.ack <= 0;
            if (port_a.cyc && port_a.stb && !ack_a_pending) begin
                idx_a = (port_a.adr - ADDRESS) >> 2;
                if (idx_a < WORD_COUNT)
                    port_a.dat_miso <= selected_word;
                else
                    port_a.dat_miso <= 32'h00000013;
                ack_a_pending <= 1;
            end else if (ack_a_pending) begin
                port_a.ack <= 1;
                ack_a_pending <= 0;
            end
        end
    end

endmodule
