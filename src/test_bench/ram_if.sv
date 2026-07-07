interface ram_if(input bit clk, reset);

  logic [7:0] data_in, data_out;
  logic [4:0] address;
  logic write_enb, read_enb;

  clocking cb_drv @(posedge clk);
    default input #1step output #0;
    output data_in, address, write_enb, read_enb;
    input  reset;
  endclocking

  clocking cb_om @(posedge clk);
    default input #1step output #0;
    input data_out;
    input read_enb;
  endclocking

  clocking cb_im @(posedge clk);
    default input #1step output #0;
    input data_in, address, write_enb, read_enb;
    input reset;
  endclocking

  modport drv(clocking cb_drv);
  modport mo (clocking cb_om);
  modport mi (clocking cb_im);

endinterface
