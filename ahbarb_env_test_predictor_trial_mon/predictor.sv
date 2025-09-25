class predictor extends uvm_component;
    `uvm_component_utils(predictor)
    
    function new(string name = "predictor", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void predict_outputs(
        input ahb_transaction actual_trans,
        output ahb_transaction exp_trans
    );
        
        bit te_req, sbus_req;
        bit access_error;
        bit [3:0] expected_bwe;
        
        exp_trans      = ahb_transaction::type_id::create("exp_trans");
        
        //Determine if there are valid AHB requests
        te_req = (actual_trans.src_i == SRC_TE) && actual_trans.te_htrans == HTRANS_NONSEQ && actual_trans.te_hready_i;
        sbus_req = (actual_trans.src_i == SRC_SBUS) && actual_trans.sbus_hsel && actual_trans.sbus_htrans == HTRANS_NONSEQ && actual_trans.sbus_hready_i;
        
        //TE Interface outputs (ALWAYS fixed following spec define)
        exp_trans.te_hrdata = 32'h0;      // Always 0 s
        exp_trans.te_hready_o = 1'b1;   // Always ready
        exp_trans.te_hresp = 1'b0;        // Always OKAY
        
        //Sbus with error resp
        access_error = 0;
        if (sbus_req) begin
            // if (actual_trans.sbus_hresp) begin
            if (!actual_trans.sbus_hauser && actual_trans.mode_sbus) begin
                access_error = 1;
                // `uvm_info(get_type_name(), "=== TEST error response ===", UVM_LOW)
            end 
        end
        
        //Calculate expected value when SBUS/TE access to SRAM
        if ((sbus_req && !access_error && actual_trans.last_sbus_hready_o) || te_req) begin
            // `uvm_info(get_type_name(), "=== START CHECK SRAM ===", UVM_LOW)
            // `uvm_info("Predictor", $sformatf("Predictor 1 capture from DUT to SB trans: %s", actual_trans.sprint()), UVM_MEDIUM)
            if (actual_trans.sbus_hwrite || actual_trans.te_hwrite) begin
                exp_trans.sram_ce            = 1'b1;
                exp_trans.sram_addr          = te_req ? actual_trans.te_haddr[9:2] : actual_trans.sbus_haddr[9:2];
                expected_bwe                 = te_req ? cal_bwe(actual_trans.te_hsize, actual_trans.te_haddr[1:0]) : cal_bwe(actual_trans.sbus_hsize, actual_trans.sbus_haddr[1:0]);
                exp_trans.sram_bwe           = expected_bwe;
                exp_trans.sram_wdata         = te_req ? actual_trans.te_hwdata : actual_trans.sbus_hwdata;
                // `uvm_info(get_type_name(), "=== CHECK WRITE TO SRAM ===", UVM_LOW)
            end
            else if (!actual_trans.sbus_hwrite) begin
                exp_trans.sram_ce    = 1'b1;
                exp_trans.sram_addr  = actual_trans.sbus_haddr[9:2];
                exp_trans.sram_bwe   = 4'h0;    // Read access
                exp_trans.sram_wdata = 0;       // Don't care for reads
                // `uvm_info(get_type_name(), "=== SRAM IS READ ===", UVM_LOW)
            end
        end
        else if (sbus_req && actual_trans.te_htrans == HTRANS_NONSEQ && actual_trans.te_hready_i && access_error) begin
            exp_trans.sram_ce    = 1'b1;
            exp_trans.sram_addr  = actual_trans.te_haddr[9:2];
            exp_trans.sram_bwe   = cal_bwe(actual_trans.te_hsize, actual_trans.te_haddr[1:0]);
            exp_trans.sram_wdata = actual_trans.te_hwdata;
        end
        else begin
            // `uvm_info("Predictor", $sformatf("Predictor 2 capture from DUT to SB trans: %s", actual_trans.sprint()), UVM_MEDIUM)
            exp_trans.sram_ce    = 1'b0;
            exp_trans.sram_addr  = 8'h0;
            exp_trans.sram_bwe   = 4'h0;
            exp_trans.sram_wdata = 32'h0;
            // `uvm_info(get_type_name(), "=== There is no request access to SRAM ===", UVM_LOW)
        end
        
        //Calculate expected value when SRAM is read from SBUS
        if (sbus_req && !access_error && actual_trans.last_sbus_hready_o) begin
            // Completing an SBUS transaction
            exp_trans.sbus_hready_o = 1'b1;
            exp_trans.sbus_hresp    = 1'b0;  // OKAY response
            // `uvm_info(get_type_name(), "=== START CHECK READ FROM SRAM BY SBUS ===", UVM_LOW)
            if (!actual_trans.sbus_hwrite && actual_trans.sbus_hready_o) begin
                exp_trans.sbus_hrdata = actual_trans.sram_rdata;  // Return read data
                // `uvm_info(get_type_name(), "=== READ FROM SRAM BY SBUS ===", UVM_LOW)
            end
            else begin
                exp_trans.sbus_hrdata = 32'h0;       // Don't care for write
                // `uvm_info(get_type_name(), "=== SBUS WRITE TO SRAM ===", UVM_LOW)
            end
        end
        else if (sbus_req && access_error && actual_trans.last_sbus_hready_o) begin
            // SBUS access error
            exp_trans.sbus_hready_o = 1'b1;
            exp_trans.sbus_hresp    = 1'b1;      // ERROR response
            exp_trans.sbus_hrdata   = 32'h0;
            `uvm_info(get_type_name(), "=== ACCESS TO SRAM BY SBUS WITH ERR RESP ===", UVM_LOW)
        end
        else if (sbus_req && !actual_trans.last_sbus_hready_o) begin
            // SBUS access error
            exp_trans.sbus_hready_o = actual_trans.sbus_hready_o;
            exp_trans.sbus_hresp    = actual_trans.sbus_hresp;
            exp_trans.sbus_hrdata   = 32'h0;
            `uvm_info(get_type_name(), "=== NOT READY FOR NEW REQ ===", UVM_LOW)
        end
    endfunction
    
    function logic [3:0] cal_bwe( logic [1:0] size, logic [1:0] addr);
        case (size)
            HSIZE_BYTE: begin
                case (addr)
                    2'b00: return 4'b0001;
                    2'b01: return 4'b0010;
                    2'b10: return 4'b0100;
                    2'b11: return 4'b1000;
                endcase
            end
            HSIZE_HWORD: begin
                case (addr[1])
                    1'b0:  return 4'b0011;
                    1'b1:  return 4'b1100;
                endcase
            end
            HSIZE_WORD, HSIZE_DWORD: begin
                return 4'b1111;
            end
            default: return 4'b0000;
        endcase
    endfunction
endclass
