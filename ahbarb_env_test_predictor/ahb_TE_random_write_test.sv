class ahb_TE_random_write_test extends ahb_base_test;
    `uvm_component_utils(ahb_TE_random_write_test)
    
    function new(string name = "ahb_TE_random_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        ahb_TE_random_write_seq seq;
        phase.raise_objection(this);
        
        seq = ahb_TE_random_write_seq::type_id::create("seq");
        seq.start(env.te_ag.sequencer);
        
        phase.drop_objection(this);
    endtask
endclass
