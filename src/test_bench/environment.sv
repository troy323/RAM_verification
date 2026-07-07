class environment;

  generator      gen;
  driver         drv;
  input_monitor  imon;
  output_monitor omon;
  reference      ref_model;
  scoreboard     scb;

  mailbox #(transaction) mbx_gd;
  mailbox #(transaction) mbx_mr;
  mailbox #(transaction) mbx_rs;
  mailbox #(transaction) mbx_ms;

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

    gen       = new(mbx_gd);
    drv       = new(mbx_gd, drv_vif);
    imon      = new(mi_vif, mbx_mr);
    omon      = new(mbx_ms, mo_vif);
    ref_model = new(mbx_rs, mbx_mr);
    scb       = new(mbx_rs, mbx_ms);
  endfunction

  task run();
    $display("[ENV] Starting all components at time %0t", $time);
    fork
      gen.start();
      drv.start();
      imon.start();
      omon.start();
      ref_model.start();
      scb.run();
    join_none
  endtask

  task wait_for_done();
    @(gen.done);
    $display("[ENV] Generator done, draining pipeline at time %0t", $time);
    #500;
  endtask

  task post_run();
    $display("==============================");
    $display("       TEST SUMMARY");
    $display("==============================");
    $display("  Pass : %0d", scb.pass_count);
    $display("  Fail : %0d", scb.fail_count);
    $display("  Total: %0d", scb.pass_count + scb.fail_count);
    $display("==============================");
  endtask

endclass
