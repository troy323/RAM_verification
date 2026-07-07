class generator;

  transaction tr;
  mailbox #(transaction) mbx_gd;
  event done;
  int num_transactions;

  function new(mailbox #(transaction) mbx_gd, int num_transactions = 12);
    this.mbx_gd = mbx_gd;
    this.num_transactions = num_transactions;
    tr = new();
  endfunction

  task start();
    for (int i = 0; i < num_transactions; i++) begin
      assert(tr.randomize()) else $display("[GEN] Randomization failed");
      mbx_gd.put(tr.copy());
      $display("[GEN] [%0d/%0d] data_in:%0h, address:%0d, write_enb:%0b, read_enb:%0b",
               i+1, num_transactions, tr.data_in, tr.address, tr.write_enb, tr.read_enb);
    end
    $display("[GEN] All %0d transactions generated", num_transactions);
    -> done;
  endtask

endclass
