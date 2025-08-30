class ahb_te_err_rsp_2nd_cycle_seq extends ahb_base_sequence;
  int num_trans = 50;
  int cnt = 0;
    `uvm_object_utils(ahb_te_err_rsp_2nd_cycle_seq)
    
    function new(string name = "ahb_te_err_rsp_2nd_cycle_seq");
        super.new(name);
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            //Randomize generate stimuli
            assert(req.randomize() with {
              src_i == SRC_TE;
              te_hwrite == 1;
              te_hsize == 2;
              te_haddr inside {[0:1023]};
              te_hauser == 1'b1;
              // te_htrans inside {0,2};
              te_htrans dist {0:=80, 2:=20};
              // te_htrans == 0;
              // if (num_trans > 2000) te_htrans == 0;
              // else te_htrans dist {0:=80, 2:=20};
            });
            start_item(req);
            finish_item(req);
            // cnt++;
            // if (cnt >= num_trans)
                // req.te_htrans = 0;
        end
    endtask
endclass

