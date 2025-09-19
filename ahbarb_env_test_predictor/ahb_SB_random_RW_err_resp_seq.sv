class ahb_SB_random_RW_err_resp_seq extends ahb_base_sequence;
  int num_trans = 50;
  logic  trigger;
  int    cnt = 0;
    `uvm_object_utils(ahb_SB_random_RW_err_resp_seq)
    
    function new(string name = "ahb_SB_random_RW_err_resp_seq");
        super.new(name);
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            assert(req.randomize() with {
                src_i == SRC_SBUS;
                sbus_htrans dist {HTRANS_IDLE:/50, HTRANS_NONSEQ:/50};
                sbus_hauser == 0;
                sbus_hsize inside {0,1,2,3};
                mode_sbus == 1;
                sbus_haddr inside {[0:1023]};
            });
            start_item(req);
            finish_item(req);
            cnt++;
            //if (cnt == 100)
            //    break;
       end
    endtask
endclass
