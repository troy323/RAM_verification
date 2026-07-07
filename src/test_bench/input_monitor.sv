class input_monitor;

  transaction tr;
  mailbox #(transaction) mbx_mr;
  virtual ram_if.mi vif;

  covergroup cg;
    cp1: coverpoint tr.write_enb;
    cp2: coverpoint tr.read_enb;
    cp3: coverpoint tr.data_in  { bins b1[] = {[0:255]}; }
    cp4: coverpoint tr.address  { bins b2[] = {[0:31]};  }
    cp5: cross cp1, cp2;
  endgroup

  function new(virtual ram_if.mi vif, mailbox #(transaction) mbx_mr);
    this.vif    = vif;
    this.mbx_mr = mbx_mr;
    cg = new();
  endfunction

  task start();
    $display("[IMON] Input monitor started at time %0t", $time);
    forever begin
      @(vif.cb_im);
      if (vif.cb_im.reset === 1'b0) continue;     // skip during active-low reset
      tr = new();
      tr.data_in   = vif.cb_im.data_in;
      tr.address   = vif.cb_im.address;
      tr.write_enb = vif.cb_im.write_enb;
      tr.read_enb  = vif.cb_im.read_enb;
      cg.sample();
      mbx_mr.put(tr);
      $display("[IMON] addr:%0d, data:%0h, w:%0b, r:%0b at time %0t",
                tr.address, tr.data_in, tr.write_enb, tr.read_enb, $time);
    end
  endtask

endclass
