import riscv_pkg::*;

module fpga_top #(
    parameter int unsigned ram_size = 1024,
    parameter int unsigned rom_size = 76,
    parameter init_mem = "prime_sieve_uart.hex",
    parameter int unsigned CLKS_PER_BIT = 10417 
)(
    input logic clk,
    input logic btnC,
    output logic RsTx,
    output logic [1:0] led
);

    logic rst;
    assign rst = btnC;

    logic illegal_instr;

    logic [XLEN-1:0] fpga_mem_addr;
    logic [XLEN-1:0] fpga_mem_wdata;
    logic fpga_mem_write;

    top #(
        .ram_size(ram_size),
        .rom_size(rom_size),
        .init_mem(init_mem)
    ) u_cpu (
        .clk(clk),
        .rst(rst),
        .illegal_instr(illegal_instr),
        .fpga_mem_addr(fpga_mem_addr),
        .fpga_mem_wdata(fpga_mem_wdata),
        .fpga_mem_write(fpga_mem_write)
    );

    //Anything written to the UART_ADDR memory address in dmem 
    //automatically has its least significant byte sent over UART.
    localparam logic [XLEN-1:0] UART_ADDR = 32'hFFFF_FFF0;

    logic uart_start;
    assign uart_start = fpga_mem_write & (fpga_mem_addr == UART_ADDR);

    logic uart_busy;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart (
        .clk(clk),
        .rst(rst),
        .tx_data(fpga_mem_wdata[7:0]),
        .tx_start(uart_start),
        .tx_busy(uart_busy),
        .tx_serial(RsTx)
    );

    assign led[0] = illegal_instr;
    assign led[1] = uart_busy;

endmodule