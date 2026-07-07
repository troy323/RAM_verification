class output_monitor;

  virtual ram_if.mo vif;
  mailbox #(transaction) mbx_ms;
  transaction tr;

  function new(mailbox #(transaction) mbx_ms, virtual ram_if.mo vif);
    this.mbx_ms = mbx_ms;
    this.vif    = vif;
  endfunction

  task start();
    $display("[OMON] Output monitor started at time %0t", $time);
    forever begin
      @(vif.cb_om);
      if (vif.cb_om.read_enb) begin
        @(vif.cb_om);                              // wait 1 cycle for registered output
        tr = new();
        tr.data_out = vif.cb_om.data_out;
        mbx_ms.put(tr);
        $display("[OMON] data_out:%0h at time %0t", vif.cb_om.data_out, $time);
      end
    end
  endtask

endclass
