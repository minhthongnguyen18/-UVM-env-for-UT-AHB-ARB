class ahb_err_rsp_2nd_cycle_test extends ahb_base_test;
  `uvm_component_utils(ahb_err_rsp_2nd_cycle_test)
  
  function new(string name = "ahb_err_rsp_2nd_cycle_test", uvm_component parent);
      super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
      begin
          ahb_te_err_rsp_2nd_cycle_seq te_seq;
          te_seq = ahb_te_err_rsp_2nd_cycle_seq::type_id::create("te_seq");
          // te_seq.num_trans=50;
          te_seq.start(env.te_ag.sequencer);
      end
      begin
          ahb_sbus_err_rsp_2nd_cycle_seq sbus_seq;
          sbus_seq = ahb_sbus_err_rsp_2nd_cycle_seq::type_id::create("sbus_seq");
          // sbus_seq.num_trans=50;
          @(posedge env.sbus_ag.vif.clk_i);  
          sbus_seq.start(env.sbus_ag.sequencer);
      end
    join_none
    wait fork;
    phase.drop_objection(this);
  endtask
endclass