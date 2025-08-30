class predictor extends uvm_component;
    `uvm_component_utils(predictor)
    
    function new(string name = "predictor", uvm_component parent);
        super.new(name, parent);
        reset_predictor();
    endfunction
    
    typedef struct {
        logic is_te;           // 1 if TE request, 0 if SBUS request
        logic [31:0] addr;
        logic [2:0]  size;
        logic write;
        logic [31:0] wdata;
        logic auser;           // debug privilege
        logic valid;
    } pending_req_t;
    
    pending_req_t pending_req;
    logic has_pending_req;
    
    function void reset_predictor();
        has_pending_req = 0;
        pending_req = '{default: 0};
    endfunction
    
    function void predict_outputs(
        input ahb_arbiter_transaction txn,
        output ahb_arbiter_transaction expected
    );
        
        bit te_requesting, sbus_requesting;
        bit access_error;
        bit [3:0] expected_bwe;
        bit [8:0] sram_addr;
        
        // Copy input transaction
        expected.copy(txn);
        
        // ===== STEP 1: Determine if there are valid AHB requests =====
        te_requesting = txn.te_hready_s && 
                       (txn.te_htrans_s == HTRANS_NONSEQ || txn.te_htrans_s == HTRANS_SEQ);
        
        sbus_requesting = txn.sbus_hready_s && txn.sbus_hsel_s &&
                         (txn.sbus_htrans_s == HTRANS_NONSEQ || txn.sbus_htrans_s == HTRANS_SEQ);
        
        // ===== STEP 2: TE Interface outputs (ALWAYS fixed per spec) =====
        expected.te_hrdata_s = 32'h0;      // Always 0 
        expected.te_hready_s_out = 1'b1;   // Always ready
        expected.te_hresp_s = 1'b0;        // Always OKAY
        
        // ===== STEP 3: Arbitration Logic (TE has priority) =====
        pending_req_t current_req;
        bit has_current_req = 0;
        
        if (te_requesting) begin
            // TE wins arbitration (higher priority)
            current_req.is_te = 1;
            current_req.addr = txn.te_haddr_s;
            current_req.size = txn.te_hsize_s;
            current_req.write = txn.te_hwrite_s;
            current_req.wdata = txn.te_hwdata_s;
            current_req.auser = txn.te_hauser_s;
            current_req.valid = 1;
            has_current_req = 1;
        end else if (sbus_requesting) begin
            // SBUS gets access only if TE is not requesting
            current_req.is_te = 0;
            current_req.addr = txn.sbus_haddr_s;
            current_req.size = txn.sbus_hsize_s;
            current_req.write = txn.sbus_hwrite_s;
            current_req.wdata = txn.sbus_hwdata_s;
            current_req.auser = txn.sbus_hauser_s;
            current_req.valid = 1;
            has_current_req = 1;
        end
        
        // ===== STEP 4: Debug Privilege Checking =====
        access_error = 0;
        if (has_current_req && !current_req.is_te) begin
            // Only check SBUS requests for debug privilege
            if (txn.mode_sbus_require_dbgpriv && !current_req.auser) begin
                access_error = 1;
            end
        end
        
        // ===== STEP 5: Handle pending request from previous cycle =====
        bit process_pending = has_pending_req;
        bit accept_new_req = has_current_req && !access_error;
        bit backpressure_needed = accept_new_req && process_pending;
        
        // ===== STEP 6: Calculate SRAM interface outputs =====
        if (process_pending) begin
            expected.tram_ce = 1'b1;
            sram_addr = pending_req.addr[9:2];  // Word-aligned address
            expected.tram_a = sram_addr;
            
            if (pending_req.write) begin
                expected_bwe = calculate_byte_enables(pending_req.size, pending_req.addr[1:0]);
                expected.tram_bwe = expected_bwe;
                expected.tram_d = pending_req.is_te ? txn.te_hwdata_s : txn.sbus_hwdata_s;
            end else begin
                expected.tram_bwe = 4'h0;  // Read access
                expected.tram_d = 32'h0;   // Don't care for reads
            end
        end else begin
            expected.tram_ce = 1'b0;
            expected.tram_bwe = 4'h0;
            expected.tram_d = 32'h0;
            expected.tram_a = 9'h0;
        end
        
        // ===== STEP 7: Calculate SBUS interface outputs =====
        if (process_pending && !pending_req.is_te) begin
            // Completing an SBUS transaction
            expected.sbus_hready_s_out = 1'b1;
            expected.sbus_hresp_s = 1'b0;  // OKAY response
            
            if (!pending_req.write) begin
                expected.sbus_hrdata_s = txn.tram_q;  // Return read data
            end else begin
                expected.sbus_hrdata_s = 32'h0;       // Don't care for write
            end
        end else if (access_error && !current_req.is_te) begin
            // SBUS access error
            expected.sbus_hready_s_out = 1'b1;
            expected.sbus_hresp_s = 1'b1;      // ERROR response
            expected.sbus_hrdata_s = 32'h0;
        end else if (backpressure_needed && !current_req.is_te) begin
            // Need to backpressure SBUS
            expected.sbus_hready_s_out = 1'b0;
            expected.sbus_hresp_s = 1'b0;
            expected.sbus_hrdata_s = 32'h0;
        end else begin
            // Default SBUS outputs
            expected.sbus_hready_s_out = 1'b1;
            expected.sbus_hresp_s = 1'b0;
            expected.sbus_hrdata_s = 32'h0;
        end
        
        // ===== STEP 8: Update internal state for next cycle =====
        if (accept_new_req && !backpressure_needed) begin
            pending_req = current_req;
            has_pending_req = 1;
        end else if (process_pending) begin
            has_pending_req = 0;
        end
        
    endfunction
    
    function logic [3:0] cal_bwe( logic [2:0] size, logic [1:0] addr);
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
