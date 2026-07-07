
class output_monitor;

  virtual ram_if.mo vif;
  mailbox #(transaction) mbx_ms;                   
  transaction tr;

  function new(mailbox #(transaction) mbx_ms, virtual ram_if.mo vif);
    this.mbx_ms=mbx_ms;
    this.vif=vif;
  endfunction

  task start();
    repeat(3)@(vif.cb_om); 
    forever begin
      tr=new;
      tr.data_out=vif.cb_om.data_out;
      $display("[OMON] data_out:%0d at time:%0t",tr.data_out,$time);
      mbx_ms.put(tr);
      @(vif.cb_om);
    end
  endtask 
endclass
