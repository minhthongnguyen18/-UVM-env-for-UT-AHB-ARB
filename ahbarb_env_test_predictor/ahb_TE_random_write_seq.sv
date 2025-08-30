class ahb_TE_random_write_seq extends ahb_base_sequence;
  int num_trans = 50;
    `uvm_object_utils(ahb_TE_random_write_seq)
    
    function new(string name = "ahb_TE_random_write_seq");
        super.new(name);
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            //Randomize generate stimuli
            assert(req.randomize() with {
              src_i == SRC_TE;
              te_hwrite == 1'b1;
              te_hsize  == 3'h2;
              te_hauser == 3'h1;
              te_htrans == HTRANS_IDLE;
              // te_htrans dist {0:=80, 2:=20};
              te_haddr inside {[0:1023]};
            });
            start_item(req);
            finish_item(req);
        end
    endtask
endclass

