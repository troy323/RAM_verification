
class test;
  virtual ram_if.drv drv_vif;
  virtual ram_if.mi  mi_vif;
  virtual ram_if.mo  mo_vif;
  environment env;
  
  
  function new(virtual ram_if.drv drv_vif,
               virtual ram_if.mi  mi_vif,
               virtual ram_if.mo  mo_vif);
    this.drv_vif=drv_vif;
    this.mi_vif=mi_vif;
    this.mo_vif=mo_vif;
  endfunction
  
  task run();
    env = new(this.drv_vif,this.mi_vif,this.mo_vif);
    env.build();
    env.run();
    env.post_run();
  endtask 
endclass 
  
class write_test extends test;
  transaction_write t1;
    function new(virtual ram_if.drv drv_vif,
               virtual ram_if.mi  mi_vif,
               virtual ram_if.mo  mo_vif);
      super.new(drv_vif,mi_vif,mo_vif);
    endfunction 
    
    
  task run();
    env = new(this.drv_vif,this.mi_vif,this.mo_vif);
    env.build();
    begin 
      t1=new();
      env.gen.tr=t1;
    end 
    env.run();
    env.post_run();
  endtask 
endclass 
  
  
 class read_test extends test;
   transaction_read t2;
    function new(virtual ram_if.drv drv_vif,
               virtual ram_if.mi  mi_vif,
               virtual ram_if.mo  mo_vif);
      super.new(drv_vif,mi_vif,mo_vif);
    endfunction 
    
    
  task run();
    env = new(this.drv_vif,this.mi_vif,this.mo_vif);
    env.build();
    begin 
      t2=new();
      env.gen.tr=t2;
    end 
    env.run();
    env.post_run();
  endtask 
endclass 
  
class test_regression extends test;
  transaction tr1;
  transaction_write tr2;
  transaction_read tr3;
  
  function new(virtual ram_if.drv drv_vif,
               virtual ram_if.mi  mi_vif,
               virtual ram_if.mo  mo_vif);
      super.new(drv_vif,mi_vif,mo_vif);
    endfunction
  
  task run();
    env = new(this.drv_vif, this.mi_vif, this.mo_vif);
    env.build();
 
    tr1 = new();
    env.gen.tr = tr1;
    env.run();
    env.post_run(); 
    

    env.scb.pass_count = 0; 
    env.scb.fail_count = 0;

    tr2 = new();
    env.gen.tr = tr2;
    env.run();
    env.post_run(); 
    env.scb.pass_count = 0; 
    env.scb.fail_count = 0;

    tr3 = new();
    env.gen.tr = tr3;
    env.run();
    env.post_run(); 
    
  endtask 
endclass
