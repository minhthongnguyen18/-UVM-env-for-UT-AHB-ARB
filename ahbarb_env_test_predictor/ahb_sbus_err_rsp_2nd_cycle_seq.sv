class ahb_sbus_err_rsp_2nd_cycle_seq extends ahb_base_sequence;
  int num_trans = 50;
    int cnt = 0;
    `uvm_object_utils(ahb_sbus_err_rsp_2nd_cycle_seq)
    
    function new(string name = "ahb_sbus_err_rsp_2nd_cycle_seq");
        super.new(name);
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            assert(req.randomize() with {
                src_i == SRC_SBUS;
                sbus_htrans dist {0:=20, 2:=80};
                sbus_hsize inside {0,1,2,3};
                sbus_hauser == 1'b0;
                sbus_hwrite == 1'b1;
                sbus_haddr inside {[0:1023]};
            });
            start_item(req);
            finish_item(req);
            // cnt++;
            // if (cnt >= num_trans)
                // break;
       end
    endtask
endclass
