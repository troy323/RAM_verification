class transaction;

  rand logic [7:0] data_in;
  rand logic [4:0] address;
  rand logic       write_enb;
  rand logic       read_enb;
       logic [7:0] data_out;

  constraint addr_c {
    address dist {0 :/ 5, [1:30] :/ 20, 31 :/ 5};
  }

  constraint oper_c {
    {write_enb, read_enb} != 2'b11;
  }

  constraint data_c {
    data_in inside {8'h00, 8'hFF, 8'h55, 8'hAA, [0:7]};
  }

  virtual function transaction copy();
    copy = new();
    copy.data_in   = this.data_in;
    copy.write_enb = this.write_enb;
    copy.read_enb  = this.read_enb;
    copy.address   = this.address;
    copy.data_out  = this.data_out;
    return copy;
  endfunction

endclass
