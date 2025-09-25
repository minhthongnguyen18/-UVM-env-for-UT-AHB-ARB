class ahb_te_err_rsp_2nd_cycle_seq extends ahb_base_sequence;
  int num_trans = 10000;
  logic  [1:0] prev_te_htrans;
  int cnt;
    `uvm_object_utils(ahb_te_err_rsp_2nd_cycle_seq)
    
    function new(string name = "ahb_te_err_rsp_2nd_cycle_seq");
        super.new(name);
        cnt = 0;
        prev_te_htrans = HTRANS_IDLE;
    endfunction

    task body();
       ahb_transaction req;
       repeat(num_trans) begin
            req = ahb_transaction::type_id::create("req");
            //Randomize generate stimuli
            // assert(req.randomize() with {
              // src_i == SRC_TE;
              // te_hwrite == 1;
              // te_hsize == 2;
              // te_haddr inside {[0:1023]};
              // te_hauser == 1'b1;
              // te_htrans inside {0,2};
              // if (prev_te_htrans == HTRANS_NONSEQ)
                  // te_htrans == HTRANS_NONSEQ;
              // else
                  // te_htrans inside {HTRANS_IDLE, HTRANS_NONSEQ};
            // });
            case (cnt)
                0,1: begin
                    assert(req.randomize() with { 
                        src_i       == SRC_TE;
                        te_htrans   == HTRANS_IDLE;
                    });
                end
                2,3,4: begin
                    assert(req.randomize() with {
                        src_i       == SRC_TE;
                        te_htrans   == HTRANS_NONSEQ;
                        te_hready_i == 1'b1;
                    });
                end
                5: begin
                    assert(req.randomize() with { 
                        src_i       == SRC_TE;
                        te_htrans   == HTRANS_IDLE;
                    });
                end
                default: begin
                    assert(req.randomize() with {
                        src_i       == SRC_TE;
                        te_htrans   == HTRANS_IDLE;
                    });
                end
            endcase
            
            start_item(req);
            finish_item(req);
            cnt++;
            prev_te_htrans = req.te_htrans;
        end
    endtask
endclass

