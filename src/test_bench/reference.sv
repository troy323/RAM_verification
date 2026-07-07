
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
    forever begin
      mbx_mr.get(tr);
      exp = new();
      if(!tr.reset) begin 
        mem[tr.address]=0;
        data_out<=8'bz;
      end
      else if (tr.write_enb && !tr.read_enb) begin
        mem[tr.address] = tr.data_in;
        exp.data_out=8'h0;
        $display("[REF] Write data:%0h to address:%0h at %0t", tr.data_in, tr.address,$time);
      end
      else if (tr.read_enb && !tr.write_enb) begin
        exp.address = tr.address;
        if (mem.exists(tr.address))
          exp.data_out = mem[tr.address];
        else exp.data_out = 8'h0;
        $display("[REF] Predicted read data:%0d from address:%0d at %0t", exp.data_out, exp.address,$time);
      end
      else begin 
        exp.data_out=0;
        $display("No operation at time:%0t",$time);
      end
      mbx_rs.put(exp);
      
      
    end
  endtask

endclass
