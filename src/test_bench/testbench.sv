`include "interface.sv" 

`include "ram_package.sv" 

import ram_package::*;
module top;
  bit clk, reset;

  // Clock generation: 10ns period
  always #5 clk = ~clk;
  
  initial begin 
     reset = 0;
    #20;
    reset = 1;
  end 
    

  ram_if rif(clk, reset);

  RAM dut(
    .clk       (clk),
    .reset     (reset),
    .address   (rif.address),
    .data_in   (rif.data_in),
    .write_enb (rif.write_enb),
    .read_enb  (rif.read_enb),
    .data_out  (rif.data_out)
  );
  
//   test t;
//   read_test t2;
//   write_test t3;
  test_regression tp;
  

  initial begin
    tp=new(rif.drv, rif.mi, rif.mo);
    tp.run();
    $finish;
  end

  // Waveform dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
  end

endmodule
