class driver;

  transaction tr;
  mailbox #(transaction) mbx_gd;
  virtual ram_if.drv vif;

  function new(mailbox #(transaction) mbx_gd, virtual ram_if.drv vif);
    this.mbx_gd = mbx_gd;
    this.vif    = vif;
  endfunction

  task start();
    $display("[DRV] Driver started at time %0t", $time);
    forever begin
      @(vif.cb_drv iff vif.cb_drv.reset == 1);
      $display("[DRV] Reset released at time %0t", $time);
      fork
        begin
          @(vif.cb_drv iff vif.cb_drv.reset == 0);
          $display("[DRV] Reset detected at time %0t", $time);
        end
        begin
          forever begin
            mbx_gd.get(tr);
            @(vif.cb_drv);
            vif.cb_drv.data_in   <= tr.data_in;
            vif.cb_drv.address   <= tr.address;
            vif.cb_drv.write_enb <= tr.write_enb;
            vif.cb_drv.read_enb  <= tr.read_enb;
            $display("[DRV] addr:%0d, data:%0h, w:%0b, r:%0b at time %0t",
                      tr.address, tr.data_in, tr.write_enb, tr.read_enb, $time);
          end
        end
      join_any
      disable fork;
    end
  endtask

endclass
