// ============================================================================
//  RAM Testbench — All-in-one, fully corrected
// ============================================================================
`timescale 1ns/1ns

// ──────────────────────────────────────────────────────────────────────────────
// Interface
// ──────────────────────────────────────────────────────────────────────────────
interface ram_if(input bit clk, reset);

  logic [7:0] data_in, data_out;
  logic [4:0] address;
  logic write_enb, read_enb;

  clocking cb_drv @(posedge clk);
    default input #1step output #0;
    output data_in, address, write_enb, read_enb;
    input  reset;
  endclocking

  clocking cb_om @(posedge clk);
    default input #1step output #0;
    input data_out;
    input read_enb;
  endclocking

  clocking cb_im @(posedge clk);
    default input #1step output #0;
    input data_in, address, write_enb, read_enb;
    input reset;
  endclocking

  modport drv(clocking cb_drv);
  modport mo (clocking cb_om);
  modport mi (clocking cb_im);

endinterface

// ──────────────────────────────────────────────────────────────────────────────
// Transaction
// ──────────────────────────────────────────────────────────────────────────────
class transaction;

  rand logic [7:0] data_in;
  rand logic [4:0] address;
  rand logic       write_enb;
  rand logic       read_enb;
       logic [7:0] data_out;

  constraint addr_c {
    address dist {0 :/ 5, [1:30] :/ 20, 31 :/ 5};
  }

  constraint oper_c {
    {write_enb, read_enb} != 2'b11;
  }

  constraint data_c {
    data_in inside {8'h00, 8'hFF, 8'h55, 8'hAA, [0:7]};
  }

  virtual function transaction copy();
    copy = new();
    copy.data_in   = this.data_in;
    copy.write_enb = this.write_enb;
    copy.read_enb  = this.read_enb;
    copy.address   = this.address;
    copy.data_out  = this.data_out;
    return copy;
  endfunction

endclass

// ──────────────────────────────────────────────────────────────────────────────
// Generator
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Driver
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Input Monitor — samples bus every posedge via clocking block
// ──────────────────────────────────────────────────────────────────────────────
class input_monitor;

  transaction tr;
  mailbox #(transaction) mbx_mr;
  virtual ram_if.mi vif;

  covergroup cg;
    cp1: coverpoint tr.write_enb;
    cp2: coverpoint tr.read_enb;
    cp3: coverpoint tr.data_in  { bins b1[] = {[0:255]}; }
    cp4: coverpoint tr.address  { bins b2[] = {[0:31]};  }
    cp5: cross cp1, cp2;
  endgroup

  function new(virtual ram_if.mi vif, mailbox #(transaction) mbx_mr);
    this.vif    = vif;
    this.mbx_mr = mbx_mr;
    cg = new();
  endfunction

  task start();
    $display("[IMON] Input monitor started at time %0t", $time);
    forever begin
      @(vif.cb_im);
      if (vif.cb_im.reset === 1'b0) continue;     // skip during active-low reset
      tr = new();
      tr.data_in   = vif.cb_im.data_in;
      tr.address   = vif.cb_im.address;
      tr.write_enb = vif.cb_im.write_enb;
      tr.read_enb  = vif.cb_im.read_enb;
      cg.sample();
      mbx_mr.put(tr);
      $display("[IMON] addr:%0d, data:%0h, w:%0b, r:%0b at time %0t",
                tr.address, tr.data_in, tr.write_enb, tr.read_enb, $time);
    end
  endtask

endclass

// ──────────────────────────────────────────────────────────────────────────────
// Output Monitor — captures data_out one cycle after read_enb
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Reference Model
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Scoreboard
// ──────────────────────────────────────────────────────────────────────────────
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
    pass_count  = 0;
    fail_count  = 0;
  endfunction

  task run();
    $display("[SCB] Scoreboard started at time %0t", $time);
    forever begin
      mbx_rs.get(expected);
      mbx_ms.get(actual);
      if (actual.data_out === expected.data_out) begin  // FIX: === handles z/x correctly
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

// ──────────────────────────────────────────────────────────────────────────────
// Environment
// ──────────────────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────────────────
// Top Module
// ──────────────────────────────────────────────────────────────────────────────
module top;

  bit clk, reset;

  always #5 clk = ~clk;

  ram_if rif(clk, reset);

  RAM dut(
    .clk       (clk),
    .reset     (reset),
    .address   (rif.address),
    .data_in   (rif.data_in),
    .write_enb (rif.write_enb),
    .read_enb  (rif.read_enb),
    .data_out  (rif.data_out)
  );

  environment env;

  initial begin
    reset = 0;
    #20;
    reset = 1;

    env = new(rif.drv, rif.mi, rif.mo);
    env.build();
    env.run();
    env.wait_for_done();
    env.post_run();
    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
  end

endmodule
