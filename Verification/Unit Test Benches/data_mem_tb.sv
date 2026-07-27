import riscv_pkg::*;
`timescale 1ns/1ps

module dmem_tb;
  logic clk;
  logic [XLEN-1:0] tb_byte_addr;
  logic [XLEN-1:0] tb_wdata;
  logic mem_read, mem_write;
  mem_size_e mem_size; 
  logic mem_unsigned;
  logic [XLEN-1:0] tb_read_data;

  int unsigned total_tests = 0;
  int unsigned passed_tests = 0;

  dmem #(.ram_size(1024)) duv (
    .clk(clk),
    .byte_addr(tb_byte_addr),
    .wdata(tb_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(tb_read_data)
  );

  always #5 clk = ~clk;

  task write_data(
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] data,
    input mem_size_e size, 
    input logic is_unsigned
  );

    @(negedge clk);
    mem_read = 1'b0;
    mem_write = 1'b1;

    tb_byte_addr = addr;
    tb_wdata = data;
    mem_size = size;
    mem_unsigned = is_unsigned;

    @(negedge clk);
    mem_write = 1'b0;
  endtask

  task read_data(
    input logic [XLEN-1:0] addr,
    input mem_size_e size,
    input logic is_unsigned
  );

    @(negedge clk);
    mem_read = 1'b1;
    mem_write = 1'b0;

    tb_byte_addr = addr;
    mem_size = size;
    mem_unsigned = is_unsigned;
  endtask

  initial begin
    $dumpfile("data_mem_tb.vcd");
    $dumpvars(0, dmem_tb);

    clk = 0;
    tb_byte_addr = 0;
    tb_wdata = 0;
    mem_read = 0;
    mem_write = 0;
    mem_size = MEM_BYTE;
    mem_unsigned = 0;

    $display("STARTING DATA MEMORY TESTING:");

    write_data(32'd0, 32'd12345, MEM_WORD, 1'b1);  //Testing writing a word to dmem at address 0x0.
    read_data(32'd0, MEM_WORD, 1'b1);
    total_tests++;

    #10;

    assert(tb_read_data === 32'd12345) begin
      passed_tests++;
      $display("Test 1 Passed.");
    end
    else
      $error("TEST 1 Failed:\nExpected: 32'd12345\n Got: %0d", tb_read_data);

    write_data(32'h0000_000C, 32'hAABB_CCDD, MEM_WORD, 1'b1);  //Setting up a known word for byte-level testing.
    read_data(32'h0000_000C, MEM_WORD, 1'b1);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'hAABB_CCDD) begin
      passed_tests++;
      $display("Passed Test 2");
    end
    else
      $error("Failed Test 2\nExpected: 32'hAABB_CCDD\nGot: %h", tb_read_data);
 
    write_data(32'h0000_000C, 32'h0000_0011, MEM_BYTE, 1'b1);  //Overwriting byte offset 0 only.
    read_data(32'h0000_000C, MEM_WORD, 1'b1);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'hAABB_CC11) begin
      passed_tests++;
      $display("Passed Test 3");
    end
    else
      $error("Failed Test 3\nExpected: 32'hAABB_CC11\nGot: %h", tb_read_data);
 
    write_data(32'h0000_000D, 32'h0000_0022, MEM_BYTE, 1'b1);  //Overwriting byte offset 1 only.
    read_data(32'h0000_000C, MEM_WORD, 1'b1);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'hAABB_2211) begin
      passed_tests++;
      $display("Passed Test 4");
    end
    else
      $error("Failed Test 4\nExpected: 32'hAABB_2211\nGot: %h", tb_read_data);
 
    write_data(32'h0000_000E, 32'h0000_0033, MEM_BYTE, 1'b1);  //Overwriting byte offset 2 only.
    read_data(32'h0000_000C, MEM_WORD, 1'b1);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'hAA33_2211) begin
      passed_tests++;
      $display("Passed Test 5");
    end
    else
      $error("Failed Test 5\nExpected: 32'hAA33_2211\nGot: %h", tb_read_data);
 
    write_data(32'h0000_000F, 32'h0000_0044, MEM_BYTE, 1'b1);  //Overwriting byte offset 3 only.
    read_data(32'h0000_000C, MEM_WORD, 1'b1);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'h4433_2211) begin
      passed_tests++;
      $display("Passed Test 6");
    end
    else
      $error("Failed Test 6\nExpected: 32'h4433_2211\nGot: %h", tb_read_data);

    write_data(32'h0000_0011, 32'h0000_007A, MEM_BYTE, 1'b1);  //Testing a positive byte reads the same signed or unsigned.
    read_data(32'h0000_0011, MEM_BYTE, 1'b0);
    total_tests++;
 
    #10;
 
    assert (tb_read_data === 32'h0000_007A) begin
      passed_tests++;
      $display("Passed Test 7");
    end
    else
      $error("Failed Test 7\nExpected: 32'h0000_007A\nGot: %h", tb_read_data);
    
    //Summary
    $display("DATA MEMORY TESTING COMPLETE!");
    $display("Results: %0d/%0d tests passed.", passed_tests, total_tests);
    $finish;
  end
endmodule
