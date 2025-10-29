module wishbone_interconn #(
    parameter int NUM_SLAVES = 4 ,
    parameter logic [31:0] SLAVE_ADDRESS [NUM_SLAVES] = '{default: 32'h0},
    parameter logic [31:0] SLAVE_SIZE    [NUM_SLAVES] = '{default: 32'h100}
)(
    input  logic clk,
    input  logic rst,

    input  logic [6:0] switches,   
    output logic [1:0] mode_out,     

    wishbone_interface.slave master,
    wishbone_interface.master slaves[NUM_SLAVES]
    
);

    // ---------------- Mode Decode from Switches ----------------
    logic [1:0] mode_to_slave[NUM_SLAVES];
    logic [1:0] mode;

    assign mode = switches[6:5];  
    assign mode_out = mode;

    // ---------------- Address Decode ----------------
    logic [NUM_SLAVES-1:0] select;

    always_comb begin
        for (int i = 0; i < NUM_SLAVES; i++) begin
            select[i] = master.cyc &&
                        master.adr >= SLAVE_ADDRESS[i] &&
                        master.adr <  SLAVE_ADDRESS[i] + SLAVE_SIZE[i];
        end
    end

    logic invalid_address = master.cyc && master.stb && !select;

    // ---------------- Timeout Logic ----------------
    logic [7:0] count;
    logic timeout;

    always_ff @(posedge clk) begin
        if (rst)
            count <= 0;
        else if ((master.ack || master.err) || !master.cyc)
            count <= 0;
        else if (master.cyc && master.stb && count < 8'hFF)
            count <= count + 1;
    end

    assign timeout = (count == 8'hFF);

    // ---------------- Response Aggregation ----------------
    logic [NUM_SLAVES-1:0] ack_vec, err_vec;
    logic [NUM_SLAVES-1:0][31:0] dat_miso_vec;

    generate
        for (genvar i = 0; i < NUM_SLAVES; i++) begin
            assign ack_vec[i]       = select[i] && slaves[i].ack;
            assign err_vec[i]       = select[i] && slaves[i].err;
            assign dat_miso_vec[i]  = select[i] ? slaves[i].dat_miso : 32'b0;
        end
    endgenerate

    assign master.ack = |ack_vec;
    assign master.err = |err_vec || invalid_address || timeout;

    logic [31:0] dat_miso_comb;
    always_comb begin
        dat_miso_comb = 32'b0;
        for (int i = 0; i < NUM_SLAVES; i++) begin
            if (select[i])
                dat_miso_comb = dat_miso_vec[i];  
        end
    end
    assign master.dat_miso = dat_miso_comb;

    // ---------------- Drive Slaves + Distribute Mode ----------------
    generate
        for (genvar i = 0; i < NUM_SLAVES; i++) begin
            assign slaves[i].cyc      = master.cyc;
            assign slaves[i].stb      = master.stb && select[i];
            assign slaves[i].adr      = master.adr;
            assign slaves[i].sel      = master.sel;
            assign slaves[i].we       = master.we;
            assign slaves[i].dat_mosi = master.dat_mosi;

            assign mode_to_slave[i]   = mode;
        end
    endgenerate

endmodule
