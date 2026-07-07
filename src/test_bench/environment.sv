
class environment;

  generator gen;
  driver drv;
  input_monitor  imon;
  output_monitor omon;
  reference  ref_model;
  scoreboard scb;
  event e;

  mailbox #(transaction) mbx_gd;                  
  mailbox #(transaction) mbx_mr;                   // input_mon  -> reference
  mailbox #(transaction) mbx_rs;                   // reference  -> scoreboard
  mailbox #(transaction) mbx_ms;                   // output_mon -> scoreboard

  virtual ram_if.drv drv_vif;
  virtual ram_if.mi  mi_vif;
  virtual ram_if.mo  mo_vif;

  function new(virtual ram_if.drv drv_vif,
               virtual ram_if.mi  mi_vif,
               virtual ram_if.mo  mo_vif);
    this.drv_vif = drv_vif;
    this.mi_vif  = mi_vif;
    this.mo_vif  = mo_vif;
  endfunction

  function void build();
    mbx_gd = new();
    mbx_mr = new();
    mbx_rs = new();
    mbx_ms = new();

    gen=new(mbx_gd);
    drv=new(mbx_gd, drv_vif);
    imon=new(mi_vif, mbx_mr);
    omon=new(mbx_ms, mo_vif);
    ref_model=new(mbx_rs, mbx_mr);
    scb=new(mbx_rs, mbx_ms);
  endfunction

  task run();
    fork
      gen.start();
      drv.start();
      imon.start();
      omon.start();
      ref_model.start();
      scb.run();
    join_any 
    wait(gen.mbx_gd.num() == 0); 
    
    #50;
    disable fork;
  endtask

  task post_run();

    $display("==============================");
    $display("       TEST SUMMARY");
    $display("==============================");
    $display("  Pass : %0d", scb.pass_count);
    $display("  Fail : %0d", scb.fail_count);
    $display("==============================");
    imon.display_coverage();
  endtask

endclass

