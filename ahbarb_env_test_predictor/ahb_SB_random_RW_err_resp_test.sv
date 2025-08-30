class ahb_SB_random_RW_err_resp_test extends ahb_base_test;
    `uvm_component_utils(ahb_SB_random_RW_err_resp_test)
    
    function new(string name = "ahb_SB_random_RW_err_resp_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        ahb_SB_random_RW_err_resp_seq seq;
        phase.raise_objection(this);
        
        seq = ahb_SB_random_RW_err_resp_seq::type_id::create("seq");
        seq.start(env.sbus_ag.sequencer);
        
        phase.drop_objection(this);
    endtask
endclass
