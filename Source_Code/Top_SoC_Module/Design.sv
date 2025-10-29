module Top_SOC_Module(
    input  logic clk,             // ZedBoard system clock
    input  logic rst,             // Active-high reset (pushbutton)
    input  logic [6:0] switches,  // ZedBoard switches
    input logic pipeline,
    output logic [6:0] leds,       // ZedBoard LEDs
    output logic        done
);

    // === Wishbone Interfaces ===
    wishbone_interface wb();        // CPU to interconnect
    wishbone_interface fetch();     // CPU instruction fetch bus

    // ALU output from execute stage
    logic [31:0] alu_result;
    logic        alu_valid;

    // Mode signals decoded from switches
    logic [1:0] mode;                     // For LED/debug
    logic [1:0] mode_to_slave[4];         // Sent to all slaves

    // Slave bus instances
    wishbone_interface slave_ifc[4]();    // 4 slaves: RAM, LED

    // === Wishbone RAM (Instruction Memory) ===
    wishbone_ram #(
        .ADDRESS(32'h00000000),
        .SIZE(1024)
    ) ram_inst (
        .clk(clk),
        .rst(rst),
        .port_a(fetch.slave),
        .mode(mode)
    );

    // === Wishbone LED Peripheral ===
    wishbone_led led_unit (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .leds(leds),
        .alu_result_in(alu_result),
        .alu_valid_in(alu_valid)
    );

    // === Wishbone Interconnect ===
    wishbone_interconn #(
        .NUM_SLAVES(4),
        .SLAVE_ADDRESS('{
            32'h00010000, 
            32'h00020000,  
            32'h00030000, 
            32'h00040000   
        }),
        .SLAVE_SIZE('{
            32'h100,      
            32'h100,      
            32'h100,    
            32'h100   
        })
    ) interconnect_inst (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .mode_out(mode),                
        .master(wb.slave),
        .slaves(slave_ifc)
    );

    // === CPU Core ===
    pipeline_cpu cpu_inst (
        .clk(clk),
        .rst(rst),
        .fetch_bus(fetch.master),
        .wb(wb.master),
        .ex_mem_alu_result(alu_result),
        .alu_valid(alu_valid),
        .external_interrupt(1'b0),
        .timer_interrupt(1'b0),
        .pipeline(pipeline),
        .done(done)
    );

endmodule
