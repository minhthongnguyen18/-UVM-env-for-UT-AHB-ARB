class ahb_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(ahb_transaction, ahb_scoreboard) te_exp;
    uvm_analysis_imp #(ahb_transaction, ahb_scoreboard) sbus_exp;
    
    predictor   ref_model;

    ahb_transaction tr;
    covergroup cg(ref ahb_transaction tr);
      option.per_instance = 1;
      cp_src           : coverpoint tr.src_i        {bins te={SRC_TE}; bins sb={SRC_SBUS};}
      cp_sram_ce       : coverpoint tr.sram_ce      {bins H={1}; bins L={0};}
      cp_sram_d        : coverpoint tr.sram_wdata   {bins tram_D={[32'h0:32'hffffffff]};}
      cp_sram_a        : coverpoint tr.sram_addr    {bins tram_A={[8'h0:8'hff]};}
      cp_sram_bwe      : coverpoint tr.sram_bwe     {bins B1={1}; bins B2={2}; bins B4={4}; bins B8={8}; ignore_bins HW0={3}; ignore_bins HW1={12}; bins W_DW={15};}
      cp_sram_access   : cross cp_sram_ce, cp_sram_bwe, cp_sram_a, cp_sram_d {ignore_bins CE_L=binsof(cp_sram_ce.L);}

      cp_te_hsize      : coverpoint tr.te_hsize     {bins WORD={2}; ignore_bins ignore_size={[0:1],[3:7]};}
      cp_te_hwrite     : coverpoint tr.te_hwrite    {bins WRITE={1}; ignore_bins READ={0};}
      cp_te_htrans     : coverpoint tr.te_htrans    {bins NONSEQ={2}; bins IDLE={0}; ignore_bins ignore_htrans={1,3};}
      cp_te_hready_i   : coverpoint tr.te_hready_i  {bins H={1}; ignore_bins L={0};}
      cp_te_req        : cross cp_te_hready_i, cp_te_htrans, cp_te_hsize, cp_te_hwrite;

      cp_sbus_hsize    : coverpoint tr.sbus_hsize {bins BYTE={0}; ignore_bins HAFTWORD={1}; bins WORD={2}; ignore_bins DOUBLEWORD={3};}
      cp_sbus_hsel     : coverpoint tr.sbus_hsel;
      cp_sbus_hready_i : coverpoint tr.sbus_hready_i;
      cp_sbus_htrans   : coverpoint tr.sbus_htrans {bins NONSEQ={2}; bins IDLE={0};}
      cp_sbus_hwrite   : coverpoint tr.sbus_hwrite {bins WRITE={1}; bins READ={0};}
      cp_sbus_hauser   : coverpoint tr.sbus_hauser {bins dbg_mode={1}; bins usr_mode={0};}
      cp_sbus_hrdata   : coverpoint tr.sbus_hrdata {bins HRDATA={[32'h0:32'hffffffff]};}
    //   cp_mode_sbus     : coverpoint tr.mode_sbus;
      cp_sbus_hready_o : coverpoint tr.sbus_hready_o;
    //   cp_state: coverpoint tr.state {bins IDLE={0}; bins SB_ERROR_W={1}; bins SB_ERROR_D={2}; bins TE_WRITE_D_SB_ERROR_D={3}; bins SB_WRITE_D={4}; bins TE_WRITE_D_SB_SKID_W={5}; bins SB_READ_W={6}; bins TE_WRITE_D_SB_READ_D={7}; bins SB_READ_D={8}; bins TE_WRITE_D={9};}
      cp_state: coverpoint tr.state {bins IDLE={0}; bins SB_WRITE_D={4}; bins TE_WRITE_D_SB_SKID_W={5}; bins TE_WRITE_D_SB_READ_D={7}; bins SB_READ_D={8}; bins TE_WRITE_D={9};}
    //   state: coverpoint tr.state;
      cp_sbus_req      : cross cp_sbus_hready_i, cp_sbus_htrans, cp_sbus_hsel, cp_sbus_hsize, cp_sbus_hwrite, cp_sbus_hrdata;
    endgroup

    covergroup err_check_cg(ref ahb_transaction tr);
      option.per_instance = 1;
      cp_src           : coverpoint tr.src_i        {bins te={SRC_TE}; bins sb={SRC_SBUS};}
      cp_sram_ce       : coverpoint tr.sram_ce      {bins H={1}; bins L={0};}
      cp_sram_d        : coverpoint tr.sram_wdata   {bins tram_D={[32'h0:32'hffffffff]};}
      cp_sram_a        : coverpoint tr.sram_addr    {bins tram_A={[8'h0:8'hff]};}
      cp_sram_bwe      : coverpoint tr.sram_bwe     {ignore_bins B1={1}; ignore_bins B2={2}; ignore_bins B4={4}; ignore_bins B8={8}; ignore_bins HW0={3}; ignore_bins HW1={12}; bins W_DW={15};}
      cp_sram_access   : cross cp_sram_ce, cp_sram_bwe, cp_sram_a, cp_sram_d {ignore_bins CE_L=binsof(cp_sram_ce.L);}

      cp_te_hsize      : coverpoint tr.te_hsize     {bins WORD={2}; ignore_bins ignore_size={[0:1],[3:7]};}
      cp_te_hwrite     : coverpoint tr.te_hwrite    {bins WRITE={1}; ignore_bins READ={0};}
      cp_te_htrans     : coverpoint tr.te_htrans    {bins NONSEQ={2}; bins IDLE={0}; ignore_bins ignore_htrans={1,3};}
      cp_te_hready_i   : coverpoint tr.te_hready_i  {bins H={1}; ignore_bins L={0};}
      cp_te_req        : cross cp_te_hready_i, cp_te_htrans, cp_te_hsize, cp_te_hwrite;

      cp_sbus_hsize    : coverpoint tr.sbus_hsize {bins BYTE={0}; ignore_bins HAFTWORD={1}; bins WORD={2}; ignore_bins DOUBLEWORD={3};}
      cp_sbus_hsel     : coverpoint tr.sbus_hsel;
      cp_sbus_hready_i : coverpoint tr.sbus_hready_i;
      cp_sbus_htrans   : coverpoint tr.sbus_htrans {bins NONSEQ={2}; bins IDLE={0};}
      cp_sbus_hwrite   : coverpoint tr.sbus_hwrite {bins WRITE={1}; bins READ={0};}
      cp_sbus_hauser   : coverpoint tr.sbus_hauser {bins dbg_mode={1}; bins usr_mode={0};}
      cp_sbus_hrdata   : coverpoint tr.sbus_hrdata {bins HRDATA={[32'h0:32'hffffffff]};}
    //   cp_mode_sbus     : coverpoint tr.mode_sbus;
      cp_sbus_hready_o : coverpoint tr.sbus_hready_o;
      cp_sbus_hresp_o  : coverpoint tr.sbus_hresp;
    //   cp_state: coverpoint tr.state {bins IDLE={0}; bins SB_ERROR_W={1}; bins SB_ERROR_D={2}; bins TE_WRITE_D_SB_ERROR_D={3}; bins SB_WRITE_D={4}; bins TE_WRITE_D_SB_SKID_W={5}; bins SB_READ_W={6}; bins TE_WRITE_D_SB_READ_D={7}; bins SB_READ_D={8}; bins TE_WRITE_D={9};}
      cp_state: coverpoint tr.state {bins IDLE={0}; bins SB_WRITE_D={4}; bins TE_WRITE_D_SB_SKID_W={5}; bins SB_ERROR_D={2}; bins TE_WRITE_D_SB_ERROR_D={3};}
    //   state: coverpoint tr.state;
      cp_sbus_req      : cross cp_sbus_hready_i, cp_sbus_htrans, cp_sbus_hsel, cp_sbus_hsize, cp_sbus_hwrite;
    endgroup

    // Statistics counters
    int total_scenarios;
    int passed_scenarios;
    int failed_scenarios;
    
    // Error tracking
    int te_interface_errors;
    int sbus_interface_errors;
    int sram_interface_errors;
    int arbitration_errors;
    int privilege_check_errors;
    int cov_res;

    // Configuration
    // logic enable_detailed_logging = 1;
    logic check_te_outputs        = 0;        // TE outputs should be constant
    logic check_sbus_outputs      = 0;
    logic check_sram_outputs      = 0;
    logic check_te_sbus_outputs   = 1;
    logic check_arbitration       = 0;       // Priority and backpressure
    bit   enable_err_cov;

    `uvm_component_utils(ahb_scoreboard)
    
    function new(string name = "ahb_scoreboard", uvm_component parent);
        super.new(name, parent);
        te_exp   = new("te_exp", this);
        sbus_exp = new("sbus_exp", this);
        ref_model = predictor::type_id::create("ref_model", this);
        cg = new(tr);  // bind covergroup to transaction handles
        err_check_cg = new(tr);  // bind covergroup to transaction handles
        reset_counters();
        uvm_config_db#(bit)::get(this, "", "enable_err_cov", enable_err_cov);
    endfunction
    
    function void reset_counters();
        total_scenarios      = 0;
        passed_scenarios     = 0;
        failed_scenarios     = 0;
        te_interface_errors     = 0;
        sbus_interface_errors   = 0; 
        sram_interface_errors   = 0;
        arbitration_errors      = 0;
        privilege_check_errors  = 0;
    endfunction
    
    // function void build_phase(uvm_phase phase);
    //     super.build_phase(phase);
    //     `uvm_info("AHB_SCB", $sformatf("SB Build phase"), UVM_MEDIUM)
    // endfunction
    
    // Main checker function called by analysis port
    function void write(ahb_transaction actual_trans);
        ahb_transaction expected_trans;
        bit transaction_passed = 1;
        string error_summary = "";
        
        total_scenarios++;

        // Create expected transaction using behavioral model
        expected_trans = ahb_transaction::type_id::create("expected_trans");

        ref_model.predict_outputs(actual_trans, expected_trans);
        // `uvm_info("AHB_SCB", $sformatf("Check actual trans in SCB: %s", actual_trans.sprint()), UVM_MEDIUM)

        tr = actual_trans;  // point handle to current transaction
        // $display("====> tr.src_i[%d], tr.te_hsize[%d], tr.te_hwrite[%d], tr.te_htrans[%d] \n",tr.src_i, tr.te_hsize, tr.te_hwrite, tr.te_htrans);

        // Perform comparisons
        // if (check_te_outputs)  
        //     transaction_passed = check_te_interface(actual_trans, expected_trans, error_summary);

        // if (check_te_sbus_outputs) 
            transaction_passed = check_te_sbus_interface(actual_trans, expected_trans, error_summary);
        if (!enable_err_cov) begin
            cg.sample();
            cov_res = cg.get_coverage();
        end
        else begin
            err_check_cg.sample();
            cov_res = err_check_cg.get_coverage();
        end
        // if (check_te_sram_outputs) 
        //     transaction_passed = check_te_sram_interface(actual_trans, expected_trans, error_summary
        // if (check_sbus_outputs)
        //     transaction_passed = check_sbus_interface(actual_trans, expected_trans, error_summary);
            
        // if (check_sram_outputs)
        //     transaction_passed = check_sram_interface(actual_trans, expected_trans, error_summary);
        
        // Update statistics
        if (transaction_passed) begin
            passed_scenarios++;
            `uvm_info(get_type_name(), $sformatf("PASS [%0d]: Transaction verified successfully", total_scenarios), UVM_MEDIUM)
            log_mismatch_details(actual_trans, expected_trans);
        end else begin
            failed_scenarios++;
            `uvm_error(get_type_name(), $sformatf("FAIL [%0d]: %s", total_scenarios, error_summary))
            // Log detailed mismatch information
            log_mismatch_details(actual_trans, expected_trans);
        end
    endfunction
    
    // Check TE interface outputs (should be constant)
    virtual function logic check_te_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        logic passed = 1;
        if (actual.te_hrdata != expected.te_hrdata) begin
            passed = 0;
            te_interface_errors++;
            error_summary = {error_summary, "TE_HRDATA should be 0; "};
        end
        
        if (actual.te_hready_o != expected.te_hready_o) begin
            passed = 0;
            te_interface_errors++;
            error_summary = {error_summary, "TE_HREADY should be 1; "};
        end
        
        if (actual.te_hresp != expected.te_hresp) begin
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
        if (actual.sbus_hrdata != expected.sbus_hrdata) begin
            passed = 0;
            sbus_interface_errors++;
            error_summary = {error_summary, 
                $sformatf("SBUS_HRDATA: got=0x%08h exp=0x%08h; ", 
                actual.sbus_hrdata, expected.sbus_hrdata)};
        end
        
        if (actual.sbus_hready_o != expected.sbus_hready_o) begin
            passed = 0;
            sbus_interface_errors++;
            error_summary = {error_summary,
                $sformatf("SBUS_HREADY: got=%b exp=%b; ", 
                actual.sbus_hready_o, expected.sbus_hready_o)};
        end

        // if (actual.last_sbus_hready_o != expected.last_sbus_hready_o) begin
            // passed = 0;
            // sbus_interface_errors++;
            // error_summary = {error_summary,
                // $sformatf("PREV_SBUS_HREADY: got=%b exp=%b; ", 
                // actual.last_sbus_hready_o, expected.last_sbus_hready_o)};
        // end
        
        if (actual.sbus_hresp != expected.sbus_hresp) begin
            passed = 0;
            sbus_interface_errors++;
            if (expected.sbus_hresp == 1'b1) privilege_check_errors++;
            error_summary = {error_summary,
                $sformatf("SBUS_HRESP: got=%b exp=%b; ", 
                actual.sbus_hresp, expected.sbus_hresp)};
        end

        // if (actual.last_sbus_hresp != expected.last_sbus_hresp) begin
            // passed = 0;
            // sbus_interface_errors++;
            // error_summary = {error_summary,
                // $sformatf("PREV_SBUS_HRESP: got=%b exp=%b; ", 
                // actual.last_sbus_hresp, expected.last_sbus_hresp)};
        // end
        
        return passed;
    endfunction
    
    virtual function bit check_te_sbus_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        bit sbus_passed = 1;
        bit te_passed = 1;
        bit sram_te_passed = 1;
        bit sram_sbus_passed = 1;
        if (actual.src_i == SRC_TE && actual.te_htrans && actual.te_hready_i) begin
            te_passed = check_te_interface(actual,expected,error_summary);
            sram_te_passed = check_sram_interface(actual,expected,error_summary);
            `uvm_info(get_type_name(), "=== CHECK TE WRITE TO SRAM ===", UVM_LOW)
        end
        else if (actual.src_i == SRC_SBUS && actual.sbus_htrans == HTRANS_NONSEQ && actual.sbus_hready_i && actual.sbus_hsel) begin
            sbus_passed = check_sbus_interface(actual,expected,error_summary);
            sram_sbus_passed = check_sram_interface(actual,expected,error_summary);
            `uvm_info(get_type_name(), "=== CHECK READ/WRITE SRAM BY SBUS ===", UVM_LOW)
        end

        return (sbus_passed && te_passed && sram_te_passed && sram_sbus_passed);
    endfunction
    
    // Check SRAM interface outputs  
    virtual function bit check_sram_interface(
        ahb_transaction actual,
        ahb_transaction expected,
        ref string error_summary
    );
        bit passed = 1;
        
        if (actual.sram_ce != expected.sram_ce) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary, $sformatf("sram_CE: got=%b exp=%b; ", actual.sram_ce, expected.sram_ce)};
        end
        
        if (actual.sram_bwe != expected.sram_bwe) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary, $sformatf("sram_BWE: got=0x%h exp=0x%h; ", actual.sram_bwe, expected.sram_bwe)};
        end
        
        if (actual.sram_addr != expected.sram_addr) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary, $sformatf("sram_addr: got=0x%03h exp=0x%03h; ", actual.sram_addr, expected.sram_addr)};
        end
        
        if (actual.sram_wdata != expected.sram_wdata) begin
            passed = 0;
            sram_interface_errors++;
            error_summary = {error_summary, $sformatf("sram_wdata: got=0x%08h exp=0x%08h; ", actual.sram_wdata, expected.sram_wdata)};
        end
        
        return passed;
    endfunction
    
    // Log detailed mismatch information
    virtual function void log_mismatch_details(
        ahb_transaction actual,
        ahb_transaction expected
    );
        `uvm_info(get_type_name(), "=== LOG DETAILS ===", UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("Inputs: TE_REQ(haddr=0x%08h,hwrite=%b,hsize=%0d,htrans=%0d, hwdata=0x%08h) SBUS_REQ(haddr=0x%08h,hwrite=%b,hsize=%0d,htrans=%0d,hsel=%b,hwdata=0x%08h)",
            actual.te_haddr, actual.te_hwrite, actual.te_hsize, actual.te_htrans, actual.te_hwdata,
            actual.sbus_haddr, actual.sbus_hwrite, actual.sbus_hsize, actual.sbus_htrans, actual.sbus_hsel, actual.sbus_hwdata), 
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("SRAM: CE=%b/%b BWE=0x%h/0x%h A=0x%03h/0x%03h D=0x%08h/0x%08h Q=0x%08h",
            actual.sram_ce, expected.sram_ce, actual.sram_bwe, expected.sram_bwe,
            actual.sram_addr, expected.sram_addr, actual.sram_wdata, expected.sram_wdata, actual.sram_rdata),
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("SBUS: hready_o=%b/%b hresp=%b/%b hrdata=0x%08h/0x%08h",
            actual.sbus_hready_o, expected.sbus_hready_o,
            actual.sbus_hresp, expected.sbus_hresp,
            actual.sbus_hrdata, expected.sbus_hrdata),
            UVM_LOW)
    endfunction
    
    // Print progress summary
    virtual function void print_progress_summary();
        `uvm_info(get_type_name(), 
            $sformatf("PROGRESS: %0d trans, %0d pass, %0d fail (%.1f%% pass rate)",
            total_scenarios, passed_scenarios, failed_scenarios,
            (real'(passed_scenarios) / real'(total_scenarios)) * 100.0), 
            UVM_LOW)
    endfunction
    
    // Report phase - final summary
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
         // progress report
        print_progress_summary();
        
        `uvm_info(get_type_name(), "========== FINAL VERIFICATION REPORT ==========", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Scenarios: %0d", total_scenarios), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Coverage: %.2f%%", cov_res), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Passed: %0d", passed_scenarios), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Failed: %0d", failed_scenarios), UVM_LOW)
        
        if (total_scenarios > 0) begin
            real pass_rate = (real'(passed_scenarios) / real'(total_scenarios)) * 100.0;
            `uvm_info(get_type_name(), $sformatf("Pass Rate: %.2f%%", pass_rate), UVM_LOW)
            
            if (failed_scenarios > 0) begin
                `uvm_info(get_type_name(), "ERROR BREAKDOWN:", UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  TE Interface Errors: %0d", te_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  SBUS Interface Errors: %0d", sbus_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  SRAM Interface Errors: %0d", sram_interface_errors), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("  Privilege Check Errors: %0d", privilege_check_errors), UVM_LOW)
            end
            
            if (pass_rate == 100.0) begin
                `uvm_info(get_type_name(), "STATUS: VERIFICATION PASSED!", UVM_LOW)
            end else begin
                `uvm_error(get_type_name(), "STATUS: VERIFICATION FAILED!")
            end
        end
        
        `uvm_info(get_type_name(), "============================================", UVM_LOW)
    endfunction
endclass
