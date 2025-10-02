class ahb_sbus_err_rsp_2nd_cycle_seq extends ahb_base_sequence;
  int num_trans = 10000;
  int cnt;
  logic  [1:0] prev_sbus_htrans;
    `uvm_object_utils(ahb_sbus_err_rsp_2nd_cycle_seq)
    
    function new(string name = "ahb_sbus_err_rsp_2nd_cycle_seq");
        super.new(name);
        cnt = 0;
        prev_sbus_htrans = HTRANS_IDLE;
    endfunction

    task body();
       ahb_transaction req;
    //    repeat(num_trans) begin
       while(1) begin
            req = ahb_transaction::type_id::create("req");
            case (cnt)
                0: begin
                    assert(req.randomize() with { 
                        src_i           == SRC_SBUS;
                        sbus_htrans     == HTRANS_IDLE;
                        mode_sbus       == 1'b1;
                    });
                end
                1: begin
                    assert(req.randomize() with { 
                        src_i           == SRC_SBUS;
                        sbus_htrans     == HTRANS_NONSEQ; 
                        sbus_hsel       == 1'b1;
                        sbus_hready_i   == 1'b1;
                        sbus_hwrite     == 1'b1;
                        sbus_hauser     == 1'b0;
                        sbus_hsize      == 3'h2;
                        mode_sbus       == 1'b1;
                    });
                end
                2: begin
                    assert(req.randomize() with { 
                        src_i           == SRC_SBUS;
                        sbus_htrans     == HTRANS_IDLE;
                        mode_sbus       == 1'b1;
                    });
                end
                3: begin
                    assert(req.randomize() with { 
                        src_i           == SRC_SBUS;
                        sbus_htrans     == HTRANS_NONSEQ; 
                        sbus_hsel       == 1'b1;
                        sbus_hready_i   == 1'b1;
                        sbus_hwrite     == 1'b1;
                        sbus_hauser     == 1'b0;
                        sbus_hsize      == 3'h2;
                        mode_sbus       == 1'b0;
                    });
                end
                4,5,6: begin
                    assert(req.randomize() with { 
                        src_i           == SRC_SBUS;
                        sbus_htrans     == HTRANS_IDLE; 
                        mode_sbus       == 1'b0;
                    });
                end
                default: begin
                    assert(req.randomize() with {
                        src_i == SRC_SBUS;
                        sbus_hauser == 1'b0;
                        sbus_htrans != prev_sbus_htrans; 
                        mode_sbus == 1'b1;
                    });
                end
            endcase
            
            start_item(req);
            finish_item(req);
            cnt++;
            prev_sbus_htrans = req.sbus_htrans;
            if (coverage_control::reach_cov_event.is_on()) begin
              `uvm_info("SEQ", "Coverage reached. Stopping sequence.", UVM_LOW)
              break;
            end
       end
    $display("====> cnt[%d] \n",cnt);
    endtask
endclass
