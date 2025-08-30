class ahb_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(ahb_transaction, ahb_scoreboard) te_exp;
    uvm_analysis_imp #(ahb_transaction, ahb_scoreboard) sbus_exp;
    
    predictor   ref_model;
    
//    uvm_tlm_analysis_fifo#(ahb_transaction) te_fifo;
//    uvm_tlm_analysis_fifo#(ahb_transaction) sbus_fifo;
    
    // Statistics counters
    int total_transactions;
    int passed_transactions;  
    int failed_transactions;
    
    // Error tracking
    int te_interface_errors;
    int sbus_interface_errors;
    int sram_interface_errors;
    int arbitration_errors;
    int privilege_check_errors;

    // Configuration
    logic enable_detailed_logging = 1;
    logic check_te_outputs = 0;        // TE outputs should be constant
    logic check_sbus_outputs = 1;
    logic check_sram_outputs = 1;
    logic check_arbitration = 0;       // Priority and backpressure

    `uvm_component_utils(ahb_scoreboard)
    
    function new(string name = "ahb_scoreboard", uvm_component parent);
        super.new(name, parent);
        te_exp   = new("te_exp", this);
        sbus_exp = new("sbus_exp", this);
        ref_model = predictor::type_id::create("ref_model", this);
        reset_counters();
    endfunction
    
    function void reset_counters();
        total_transactions = 0;
        passed_transactions = 0;
        failed_transactions = 0;
        te_interface_errors = 0;
        sbus_interface_errors = 0; 
        sram_interface_errors = 0;
        arbitration_errors = 0;
        privilege_check_errors = 0;
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //te_fifo   = new("te_fifo", this);
        //sbus_fifo = new("sbus_fifo", this);
        `uvm_info("AHB_SCB", $sformatf("SB Build phase completed"), UVM_MEDIUM)
    endfunction
    
//    function void connect_phase(uvm_phase phase);
//        super.connect_phase(phase);
//        te_exp.connect(te_fifo.analysis_export);
//        sbus_exp.connect(sbus_fifo.analysis_export);
//        `uvm_info("AHB_SCB", $sformatf("SB Connect phase"), UVM_MEDIUM)
//    endfunction
    
//    task run_phase(uvm_phase phase);
//        ahb_transaction te_trans, sb_trans;
//        te_trans   = ahb_transaction::type_id::create("te_trans");
//        sb_trans   = ahb_transaction::type_id::create("sb_trans");
//        `uvm_info("AHB_SCB", $sformatf("SB Run phase"), UVM_MEDIUM)
//        forever begin
//             `uvm_info("AHB_SCB", $sformatf("SB Run phase loop"), UVM_MEDIUM)
//            if (te_fifo.try_get(te_trans)) begin
//                te_wr_data = te_trans.te_hwdata;
//                te_wr_addr = te_trans.te_haddr;
//                `uvm_info("AHB_SCB", $sformatf("Check transaction in SCB 1: %s", te_trans.sprint()), UVM_MEDIUM)
//                if ( te_wr_addr == te_trans.te_haddr );
//                    `uvm_info("AHB_SCB", $sformatf("Check transaction in SCB 2: %s", te_trans.sprint()), UVM_MEDIUM)
//            end
//            if (sbus_fifo.try_get(sb_trans)) begin
//                sbus_wr_data = sb_trans.sbus_hwdata;
//                sbus_addr    = sb_trans.sbus_haddr;
//                `uvm_info("AHB_SCB", $sformatf("Check transaction in SCB 3: %s", sb_trans.sprint()), UVM_MEDIUM)
//                if ( sbus_addr == sb_trans.sbus_haddr );
//                    `uvm_info("AHB_SCB", $sformatf("Check transaction in SCB 4: %s", sb_trans.sprint()), UVM_MEDIUM)
//            end
//             #1ns;
//        end
//    endtask
    
    // Main checker function called by analysis port
    function void write(ahb_transaction actual_trans);
        ahb_transaction expected_trans;
        bit transaction_passed = 1;
        string error_summary = "";
        
        total_transactions++;

        // Create expected transaction using behavioral model
        expected_trans = ahb_transaction::type_id::create("expected_trans");

        ref_model.predict_outputs(actual_trans, expected_trans);
        
        // Perform comparisons
        if (check_te_outputs) 
            transaction_passed = check_te_interface(actual_trans, expected_trans, error_summary);
        
        if (check_sbus_outputs)
            transaction_passed = check_sbus_interface(actual_trans, expected_trans, error_summary);
            
        if (check_sram_outputs)
            transaction_passed = check_sram_interface(actual_trans, expected_trans, error_summary);
        
        // Update statistics
        if (transaction_passed) begin
            passed_transactions++;
            if (enable_detailed_logging) begin
                `uvm_info(get_type_name(), 
                    $sformatf("PASS [%0d]: Transaction verified successfully", total_transactions), 
                    UVM_HIGH)
            end
        end else begin
            failed_transactions++;
            `uvm_error(get_type_name(), 
                $sformatf("FAIL [%0d]: %s", total_transactions, error_summary))
            
            // Log detailed mismatch information
            log_mismatch_details(actual_trans, expected_trans);
        end
        
        // Periodic progress report
        if (total_transactions % 50 == 0) begin
            print_progress_summary();
        end
    endfunction
    
    // Check TE interface outputs (should be constant)
    virtual function logic check_te_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        logic passed = 1;
        
        if (actual.te_hrdata !== 32'h0) begin
            passed = 0;
            te_interface_errors++;
            error_summary = {error_summary, "TE_HRDATA should be 0; "};
        end
        
        if (actual.te_hready_o !== 1'b1) begin
            passed = 0;
            te_interface_errors++;
            error_summary = {error_summary, "TE_HREADY should be 1; "};
        end
        
        if (actual.te_hresp !== 1'b0) begin
            passed = 0;
            te_interface_errors++;
            error_summary = {error_summary, "TE_HRESP should be 0; "};
        end
        
        return passed;
    endfunction
    
    // Check SBUS interface outputs
    virtual function bit check_sbus_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        bit passed = 1;
        if (actual.state == 4'h8) begin
            if (actual.sbus_hrdata !== expected.sbus_hrdata) begin
                passed = 0;
                sbus_interface_errors++;
                error_summary = {error_summary, 
                    $sformatf("SBUS_HRDATA: got=0x%08h exp=0x%08h; ", 
                    actual.sbus_hrdata, expected.sbus_hrdata)};
            end
        end
        if (actual.sbus_hready_o !== expected.sbus_hready_o) begin
            passed = 0;
            sbus_interface_errors++;
            error_summary = {error_summary,
                $sformatf("SBUS_HREADY: got=%b exp=%b; ", 
                actual.sbus_hready_o, expected.sbus_hready_o)};
        end
        
        if (actual.sbus_hresp !== expected.sbus_hresp) begin
            passed = 0;
            sbus_interface_errors++;
            if (expected.sbus_hresp == 1'b1) privilege_check_errors++;
            error_summary = {error_summary,
                $sformatf("SBUS_HRESP: got=%b exp=%b; ", 
                actual.sbus_hresp, expected.sbus_hresp)};
        end
        
        return passed;
    endfunction
    
    // Check SRAM interface outputs  
    virtual function bit check_sram_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        bit passed = 1;
        
        if (actual.sram_ce !== expected.sram_ce) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary,
                $sformatf("sram_CE: got=%b exp=%b; ", 
                actual.sram_ce, expected.sram_ce)};
        end
        
        if (actual.sram_bwe !== expected.sram_bwe) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary,
                $sformatf("sram_BWE: got=0x%h exp=0x%h; ", 
                actual.sram_bwe, expected.sram_bwe)};
        end
        
        if (actual.sram_addr !== expected.sram_addr) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary,
                $sformatf("sram_addr: got=0x%03h exp=0x%03h; ", 
                actual.sram_addr, expected.sram_addr)};
        end
        
        if (actual.sram_wdata !== expected.sram_wdata) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary,
                $sformatf("sram_wdata: got=0x%08h exp=0x%08h; ", 
                actual.sram_wdata, expected.sram_wdata)};
        end
        
        return passed;
    endfunction
    
    // Log detailed mismatch information
    virtual function void log_mismatch_details(
        ahb_transaction actual,
        ahb_transaction expected
    );
        `uvm_info(get_type_name(), "=== MISMATCH DETAILS ===", UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("Inputs: TE_REQ(addr=0x%08h,wr=%b,sz=%0d,tr=%0d) SBUS_REQ(addr=0x%08h,wr=%b,sz=%0d,tr=%0d,sel=%b)",
            actual.te_haddr, actual.te_hwrite, actual.te_hsize, actual.te_htrans,
            actual.sbus_haddr, actual.sbus_hwrite, actual.sbus_hsize, actual.sbus_htrans, actual.sbus_hsel), 
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("SRAM: CE=%b/%b BWE=0x%h/0x%h A=0x%03h/0x%03h D=0x%08h/0x%08h",
            actual.sram_ce, expected.sram_ce, actual.sram_bwe, expected.sram_bwe,
            actual.sram_addr, expected.sram_addr, actual.sram_wdata, expected.sram_wdata),
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("SBUS: READY=%b/%b RESP=%b/%b RDATA=0x%08h/0x%08h",
            actual.sbus_hready_o, expected.sbus_hready_o,
            actual.sbus_hresp, expected.sbus_hresp,
            actual.sbus_hrdata, expected.sbus_hrdata),
            UVM_LOW)
    endfunction
    
    // Print progress summary
    virtual function void print_progress_summary();
        `uvm_info(get_type_name(), 
            $sformatf("PROGRESS: %0d trans, %0d pass, %0d fail (%.1f%% pass rate)",
            total_transactions, passed_transactions, failed_transactions,
            (real'(passed_transactions) / real'(total_transactions)) * 100.0), 
            UVM_LOW)
    endfunction
    
    // Report phase - final summary
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), "========== FINAL VERIFICATION REPORT ==========", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Transactions: %0d", total_transactions), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Passed: %0d", passed_transactions), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Failed: %0d", failed_transactions), UVM_LOW)
        
        if (total_transactions > 0) begin
            real pass_rate = (real'(passed_transactions) / real'(total_transactions)) * 100.0;
            `uvm_info(get_type_name(), $sformatf("Pass Rate: %.2f%%", pass_rate), UVM_LOW)
            
            if (failed_transactions > 0) begin
                `uvm_info(get_type_name(), "ERROR BREAKDOWN:", UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  TE Interface Errors: %0d", te_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  SBUS Interface Errors: %0d", sbus_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  SRAM Interface Errors: %0d", sram_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  Privilege Check Errors: %0d", privilege_check_errors), UVM_LOW)
            end
            
            if (pass_rate >= 100.0) begin
                `uvm_info(get_type_name(), "STATUS: VERIFICATION PASSED!", UVM_LOW)
            end else begin
                `uvm_error(get_type_name(), "STATUS: VERIFICATION FAILED!")
            end
        end
        
        `uvm_info(get_type_name(), "============================================", UVM_LOW)
    endfunction
endclass
