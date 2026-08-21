import riscv_pkg::*;

module imem #(
  parameter init_mem = "",
  parameter int unsigned rom_size = 1024
)
(
  input [XLEN-1:0] pc_addr,
  output [XLEN-1:0] instr
);

  logic [XLEN-1:0] rom [0:rom_size-1]; //Creates 4KB of memory when rom_size = 1024.
  integer i;
  
  initial begin
    for (i=0; i<rom_size; i++)
      rom[i] = 32'h0000_0013; //Preemptively fills rom with NOP instructions in case of a hex file less than rom_size words.
    if (init_mem != "")
      $readmemh(init_mem, rom); //Overwrites NOP instructions with words from the hex file.
  end

  logic [$clog2(rom_size)-1:0] windex;
  assign windex = pc_addr[$clog2(rom_size)+1:2]; 
  assign instr = (windex < rom_size) ? rom[windex] : 32'h0000_0013;
  
endmodule
