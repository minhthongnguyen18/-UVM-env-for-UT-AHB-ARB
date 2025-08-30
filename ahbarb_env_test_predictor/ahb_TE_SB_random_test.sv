class ahb_TE_SB_random_test extends ahb_base_test;
    `uvm_component_utils(ahb_TE_SB_random_test)
    
    function new(string name = "ahb_TE_SB_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        ahb_TE_SB_random_seq seq;
        phase.raise_objection(this);
        seq = ahb_TE_SB_random_seq::type_id::create("seq");
        seq.te_seqr   = env.te_ag.sequencer;
        seq.sbus_seqr = env.sbus_ag.sequencer;
        seq.start(null);
        phase.drop_objection(this);
    endtask
endclass
