
class scoreboard;

  mailbox #(transaction) mbx_rs;
  mailbox #(transaction) mbx_ms;
  transaction expected;
  transaction actual;
  int pass_count;
  int fail_count;

  function new(mailbox #(transaction) mbx_rs, mailbox #(transaction) mbx_ms);
    this.mbx_rs = mbx_rs;
    this.mbx_ms = mbx_ms;
    pass_count= 0;
    fail_count= 0;
  endfunction

  task run();
    forever begin
      mbx_rs.get(expected);
      mbx_ms.get(actual);                         
      if (actual.data_out === expected.data_out) begin
        $display("[SCB] PASS - Expected:%0h, Got:%0h", expected.data_out, actual.data_out);
        pass_count++;
      end
      else begin
        $display("[SCB] FAIL - Expected:%0h, Got:%0h", expected.data_out, actual.data_out);
        fail_count++;
      end
    end
  endtask

endclass
