class generator;
  transaction tr;
  mailbox#(transaction)mbx_gd;
  event e;
  function new(mailbox #(transaction)mbx_gd);
    this.mbx_gd=mbx_gd;
    tr=new;
  endfunction 
  
  task start();
    for(int i=0;i<200;i++)begin 
      assert(tr.randomize) else $display("fail");
      mbx_gd.put(tr.copy());
      $display("[GEN] data_in:%d ,address:%d,write_enb:%d,read_enb:%d",tr.data_in,tr.address,tr.write_enb,tr.read_enb);
    end
  endtask 
endclass

      
  
  
