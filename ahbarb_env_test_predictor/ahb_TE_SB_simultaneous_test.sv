class ahb_TE_SB_simultaneous_test extends ahb_base_test;
  `uvm_component_utils(ahb_TE_SB_simultaneous_test)
  
  function new(string name = "ahb_TE_SB_simultaneous_test", uvm_component parent);
      super.new(name, parent);
      uvm_config_db#(bit)::set(this, "*", "enable_err_cov", 0);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
      begin
          ahb_TE_random_write_seq te_seq;
          te_seq = ahb_TE_random_write_seq::type_id::create("te_seq");
          // te_seq.num_trans=50;
          te_seq.start(env.te_ag.sequencer);
      end
      begin
          ahb_SB_random_RW_seq sbus_seq;
          sbus_seq = ahb_SB_random_RW_seq::type_id::create("sbus_seq");
          // sbus_seq.num_trans=50;
          sbus_seq.start(env.sbus_ag.sequencer);
      end
    join_none
    wait fork;
    phase.drop_objection(this);
  endtask
endclass