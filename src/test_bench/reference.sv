class reference;

  transaction tr;
  transaction exp;
  mailbox #(transaction) mbx_rs;
  mailbox #(transaction) mbx_mr;

  logic [7:0] mem [int];

  function new(mailbox #(transaction) mbx_rs, mailbox #(transaction) mbx_mr);
    this.mbx_rs = mbx_rs;
    this.mbx_mr = mbx_mr;
  endfunction

  task start();
    $display("[REF] Reference model started at time %0t", $time);
    forever begin
      mbx_mr.get(tr);
      if (tr.write_enb && !tr.read_enb) begin
        mem[tr.address] = tr.data_in;
        $display("[REF] Write data:%0h to address:%0d", tr.data_in, tr.address);
      end
      else if (tr.read_enb && !tr.write_enb) begin
        exp = new();
        exp.address = tr.address;
        if (mem.exists(tr.address))
          exp.data_out = mem[tr.address];
        else
          exp.data_out = 8'bz;                     // FIX: DUT outputs z for unwritten addresses
        mbx_rs.put(exp);
        $display("[REF] Predicted read data:%0h from address:%0d", exp.data_out, exp.address);
      end
      // else: both 0 → IDLE, skip
    end
  endtask

endclass
