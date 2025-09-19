class ahb_SB_random_RW_seq extends ahb_base_sequence;
  int num_trans = 50000;
  int    cnt = 0;
  logic  [1:0] prev_sbus_htrans;
    `uvm_object_utils(ahb_SB_random_RW_seq)
    
    function new(string name = "ahb_SB_random_RW_seq");
        super.new(name);
        prev_sbus_htrans = HTRANS_IDLE;
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            assert(req.randomize() with {
                src_i == SRC_SBUS;
                sbus_hauser == 1'b1;
                mode_sbus == 1'b0;
                if (prev_sbus_htrans == HTRANS_NONSEQ)
                    sbus_htrans == HTRANS_IDLE;
                else
                    sbus_htrans inside {HTRANS_IDLE, HTRANS_NONSEQ};
            });
            start_item(req);
            finish_item(req);
            cnt++;
            prev_sbus_htrans = req.sbus_htrans;
            //if (cnt == 100)
            //    break;
       end
    endtask
endclass
