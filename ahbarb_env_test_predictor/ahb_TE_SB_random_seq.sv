class ahb_TE_SB_random_seq extends ahb_base_sequence;
    `uvm_object_utils(ahb_TE_SB_random_seq)
     te_sequencer   te_seqr;
     sbus_sequencer sbus_seqr;
    
    function
        new(string name = "ahb_TE_SB_random_seq");
        super.new(name);
    endfunction

    task body();
        fork
            begin
                ahb_TE_random_write_seq te_seq = ahb_TE_random_write_seq::type_id::create("te_seq");
                te_seq.num_trans=100;
                `uvm_info("TE_SEQ", $sformatf("Start TE sequence at time %0t", $time), UVM_LOW)
                te_seq.start(te_seqr);
            end
            begin
                ahb_SB_random_RW_seq sbus_seq = ahb_SB_random_RW_seq::type_id::create("sbus_seq");
                sbus_seq.num_trans=100;
                `uvm_info("SBUS_SEQ", $sformatf("Start SBUS sequence at time %0t", $time), UVM_LOW)
                sbus_seq.start(sbus_seqr);
            end
        join_any
        wait fork;
    endtask
endclass