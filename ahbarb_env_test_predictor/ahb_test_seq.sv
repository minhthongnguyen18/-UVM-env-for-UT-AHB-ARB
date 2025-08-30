class ahb_test_seq extends ahb_base_sequence;
    `uvm_object_utils(ahb_test_seq)
     te_sequencer   te_seqr;
     sbus_sequencer sbus_seqr;
     rand int unsigned count = 50;
     rand bit is_simultaneous;
     rand int delay;
     constraint c_delay { delay inside {[0:5]}; } // Constrain delay to reasonable range
     constraint c_simultaneous_dist { is_simultaneous dist { 1 := 30, 0 := 70 }; } // 30% simultaneous, 70% non-simultaneous
     
    function
        new(string name = "ahb_test_seq");
        super.new(name);
    endfunction

    task body();
      repeat(count) begin
        fork
          begin
            ahb_transaction t_te = ahb_transaction::type_id::create("t_te");
            assert(t_te.randomize() with {
              src_i == SRC_TE;
              te_hwrite == 1'b1;
              te_hsize == 3'h2;
              te_haddr inside {[0:255]};
              te_hauser == 1'b1;
            });
            if (!is_simultaneous) #($urandom_range(0, delay));
            start_item(t_te);
            finish_item(t_te);
          end
          begin
            ahb_transaction t_sb = ahb_transaction::type_id::create("t_sb");
            assert(t_sb.randomize() with {
                src_i == SRC_SBUS;
                sbus_haddr inside {[0:255]};
            });
            if (!is_simultaneous) #($urandom_range(0, delay));
            start_item(t_sb);
            finish_item(t_sb);
          end
        join_none
      end
      // Wait for all transactions to complete
      wait fork;
    endtask
endclass