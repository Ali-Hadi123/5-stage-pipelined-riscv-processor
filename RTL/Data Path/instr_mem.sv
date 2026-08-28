import riscv_pkg::*;

module imem #(
  parameter init_mem = "",
  parameter int unsigned rom_size = 1024
)
(
  input logic clk,
  input logic rst,
  input logic stall,
  input logic [XLEN-1:0] pc_addr,
  output logic [XLEN-1:0] instr
);

  (* rom_style = "block" *) logic [XLEN-1:0] rom [0:rom_size-1]; //Creates 4KB of memory when rom_size = 1024.
  
  integer i;
  initial begin
    for (i=0; i<rom_size; i++)
      rom[i] = 32'h0000_0013; //Preemptively fills rom with NOP instructions in case of a hex file less than rom_size words.
    if (init_mem != "")
      $readmemh(init_mem, rom); //Overwrites NOP instructions with words from the hex file.
  end

  logic [XLEN-1:0] word_index;
  assign word_index = pc_addr >> 2;

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      instr <= 32'h0000_0013;
    else if (~stall)
      instr <= (word_index < rom_size) ? rom[word_index[$clog2(rom_size)-1:0]] : 32'h0000_0013;
  end
  
endmodule
