module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    clk, rst_n, btn, sw, led, hex
);
    input clk, rst_n;
    input [2:0] btn;
    input [8:0] sw;
    output [9:0] led;
    output [27:0] hex;

    wire clk_divided, mem_we_wire;
    wire [DATA_WIDTH-1:0] mem_data_wire, mem_in_wire;
    wire [ADDR_WIDTH-1:0] mem_addr_wire, sp_wire, pc_wire;

    clk_div #(.DIVISOR(DIVISOR)) clk_div_inst (clk,rst_n,clk_divided);

    cpu #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) cpu_inst 
    (
        .clk(clk_divided), .rst_n(rst_n), .in(sw[3:0]), .mem_we(mem_we_wire), .mem_addr(mem_addr_wire),
        .mem_data(mem_data_wire), .mem_in(mem_in_wire), .sp(sp_wire), .pc(pc_wire), .out(led[4:0])
    );

    memory #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .FILE_NAME(FILE_NAME)) memory_inst 
    (
        .clk(clk_divided), .we(mem_we_wire), .addr(mem_addr_wire), .data(mem_data_wire), .out(mem_in_wire)
    );

    wire [3:0] pc_tens_wire, pc_ones_wire, sp_tens_wire, sp_ones_wire;

    bcd bcd_pc(.in(pc_wire), .tens(pc_tens_wire), .ones(pc_ones_wire));

    bcd bcd_sp(.in(sp_wire), .tens(sp_tens_wire), .ones(sp_ones_wire));
    
    ssd ssd_sp_tens(.in(sp_tens_wire), .out(hex[27:21]));

    ssd ssd_sp_ones(.in(sp_ones_wire), .out(hex[20:14]));

    ssd ssd_pc_tens(.in(pc_tens_wire), .out(hex[13:7]));

    ssd ssd_pc_ones(.in(pc_ones_wire), .out(hex[6:0]));


endmodule