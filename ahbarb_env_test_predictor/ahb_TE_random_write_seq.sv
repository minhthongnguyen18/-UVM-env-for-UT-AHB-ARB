class ahb_TE_random_write_seq extends ahb_base_sequence;
  int num_trans = 50000;
  logic  [1:0] prev_te_htrans;
  int    cnt = 0;
  
    `uvm_object_utils(ahb_TE_random_write_seq)
    
    function new(string name = "ahb_TE_random_write_seq");
        super.new(name);
        prev_te_htrans = HTRANS_IDLE;
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            //Randomize generate stimuli
            assert(req.randomize() with {
              src_i == SRC_TE;
              if (prev_te_htrans == HTRANS_NONSEQ)
                  te_htrans == HTRANS_IDLE;
              else
                  te_htrans inside {HTRANS_IDLE, HTRANS_NONSEQ};
            });
            start_item(req);
            finish_item(req);
            prev_te_htrans = req.te_htrans;
        end
    endtask
endclass

