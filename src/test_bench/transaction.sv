class transaction;
  rand logic [7:0] data_in;
  rand logic [4:0] address;
  rand logic write_enb;
  rand logic read_enb;
  logic [7:0] data_out;
  logic reset;

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
    copy.data_out=this.data_out;
    copy.reset=this.reset;
    
    return copy;
  endfunction
endclass

class transaction_write extends transaction;
  constraint oper_c {
    {write_enb, read_enb} == 2'b10;
  }

  
  virtual function transaction_write copy();
    copy = new();
    copy.data_in   = this.data_in;
    copy.write_enb = this.write_enb;
    copy.read_enb  = this.read_enb;
    copy.address   = this.address;
    copy.data_out=this.data_out;
    copy.reset=this.reset;
    
    return copy;
  endfunction
endclass 

class transaction_read extends transaction;
  constraint oper_c {
    {write_enb, read_enb} == 2'b01;
  }
  virtual function transaction_read copy();
    copy = new();
    copy.data_in   = this.data_in;
    copy.write_enb = this.write_enb;
    copy.read_enb  = this.read_enb;
    copy.address   = this.address;
    copy.data_out=this.data_out;
    copy.reset=this.reset;
    
    return copy;
  endfunction
endclass 
  
  
