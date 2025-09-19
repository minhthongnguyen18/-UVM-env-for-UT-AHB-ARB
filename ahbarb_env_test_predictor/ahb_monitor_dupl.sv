class te_monitor extends uvm_monitor;
    virtual ahb_if       vif;
    
    uvm_analysis_port #(ahb_transaction) ap;
    
    `uvm_component_utils(te_monitor)
    
    function new(string name = "te_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("TE MONITOR", "Virtual Interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        ahb_transaction trans;
        trans = ahb_transaction::type_id::create("trans");
        forever begin
            @(posedge vif.clk_i);
            //Capture from DUT to TE transaction
            // #1ns;
            if ((vif.te_htrans_s_i == HTRANS_NONSEQ) && vif.te_hwrite_s_i && vif.te_hready_s_i) begin
                trans.src_i         = SRC_TE;
                trans.te_haddr      = vif.te_haddr_s_i;
                trans.te_hsize      = vif.te_hsize_s_i;
                trans.te_hauser     = vif.te_hauser_s_i[0];
                trans.te_hwrite     = vif.te_hwrite_s_i;
                trans.te_htrans     = vif.te_htrans_s_i;
                trans.te_hrdata     = vif.te_hrdata_s_o;
                trans.te_hready_o   = vif.te_hready_s_o;
                trans.te_hresp      = vif.te_hresp_s_o;
                trans.te_hready_i   = vif.te_hready_s_i;
                // `uvm_info("AHB_MONITOR", $sformatf("Capture from DUT to TE trans AP: %s", trans.sprint()), UVM_MEDIUM)
                @(posedge vif.clk_i);
                // #1ns;
                trans.te_hwdata     = vif.te_hwdata_s_i;
                trans.state         = vif.state_i;
                trans.sram_ce       = vif.TRAM_CE;
                trans.sram_bwe      = vif.TRAM_BWE;
                trans.sram_addr     = vif.TRAM_A;
                trans.sram_wdata    = vif.TRAM_D;
                trans.sram_rdata    = vif.TRAM_Q;
                // `uvm_info("AHB_MONITOR", $sformatf("Capture from DUT to TE trans DP: %s", trans.sprint()), UVM_MEDIUM)
                ap.write(trans);
            end
            else begin
                trans.src_i         = SRC_TE;
                trans.te_haddr      = vif.te_haddr_s_i;
                trans.te_hsize      = vif.te_hsize_s_i;
                trans.te_hauser     = vif.te_hauser_s_i[0];
                trans.te_hwrite     = vif.te_hwrite_s_i;
                trans.te_htrans     = vif.te_htrans_s_i;
                trans.te_hrdata     = vif.te_hrdata_s_o;
                trans.te_hready_o   = vif.te_hready_s_o;
                trans.te_hresp      = vif.te_hresp_s_o;
                trans.te_hready_i   = vif.te_hready_s_i;
                @(posedge vif.clk_i);
                // #1ns;
                trans.te_hwdata     = vif.te_hwdata_s_i;
                trans.state         = vif.state_i;
                trans.sram_ce       = vif.TRAM_CE;
                trans.sram_bwe      = vif.TRAM_BWE;
                trans.sram_addr     = vif.TRAM_A;
                trans.sram_wdata    = vif.TRAM_D;
                trans.sram_rdata    = vif.TRAM_Q;
                // `uvm_info("AHB_MONITOR", $sformatf("Capture from DUT to TE trans DP: %s", trans.sprint()), UVM_MEDIUM)
                ap.write(trans);
            end
        end
    endtask
endclass

class sbus_monitor extends uvm_monitor;
    virtual ahb_if       vif;
    
    uvm_analysis_port #(ahb_transaction) ap;
    
    `uvm_component_utils(sbus_monitor)
    
    function new(string name = "sbus_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("SBUS MONITOR", "Virtual Interface not found")
    endfunction

    bit        skid_state;
    bit        skid_state_next;
    bit        skid_en;
    bit [31:0] skid_haddr;
    bit [2:0]  skid_hsize;
    bit        skid_hwrite;
    bit        skid_hauser;
    bit        te_req;
    bit        sbus_req;

    task run_phase(uvm_phase phase);
        ahb_transaction trans;
        trans = ahb_transaction::type_id::create("trans");
        forever begin
            @(posedge vif.clk_i);
            //Capture from DUT to TE transaction
            sbus_req = vif.sbus_htrans_s_i == HTRANS_NONSEQ && vif.sbus_hsel_s_i && vif.sbus_hready_s_i;
            te_req   = vif.te_htrans_s_i == HTRANS_NONSEQ && vif.te_hready_s_i;
            // #1ns;
            if (sbus_req && !te_req) begin
                trans.src_i           = SRC_SBUS;
                trans.sbus_hsel       = vif.sbus_hsel_s_i;
                trans.sbus_haddr      = vif.sbus_haddr_s_i;
                trans.sbus_htrans     = vif.sbus_htrans_s_i;
                trans.sbus_hwrite     = vif.sbus_hwrite_s_i;
                trans.sbus_hauser     = vif.sbus_hauser_s_i[0];
                trans.sbus_hready_i   = vif.sbus_hready_s_i;
                trans.state           = vif.state_i;
                trans.mode_sbus       = vif.mode_sbus_require_dbgpriv_i;
                trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                case (vif.sbus_hsize_s_i)
                    3'h0:       trans.sbus_hsize = 3'h0;
                    3'h1:       trans.sbus_hsize = 3'h1;
                    default:    trans.sbus_hsize = 3'h2;
                endcase
                
                if (!trans.sbus_hwrite) begin
                    @(posedge vif.clk_i);
                    // #1ns;
                    trans.last_sram_ce       = vif.TRAM_CE;
                    trans.last_sram_bwe      = 4'h0;
                    trans.last_sram_addr     = vif.TRAM_A;
                    trans.last_sram_wdata    = 32'h0;
                    // trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                    // trans.last_sbus_hresp    = vif.sbus_hresp_s_o;
                    // `uvm_info("AHB_MONITOR", $sformatf("TEST 2: %s", trans.sprint()), UVM_MEDIUM)
                end
                else begin
                    // #1ns;
                    trans.last_sram_ce       = 1'b0;
                    trans.last_sram_bwe      = 4'h0;
                    trans.last_sram_addr     = 32'h0;
                    trans.last_sram_wdata    = 32'h0;
                    // trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                    // trans.last_sbus_hresp    = vif.sbus_hresp_s_o;
                end
                //
                do begin
                    @(posedge vif.clk_i);
                end while (!vif.sbus_hready_s_o);
                if (!trans.sbus_hwrite && !trans.mode_sbus && trans.sbus_hauser) begin
                 trans.sram_ce       = trans.last_sram_ce;
                 trans.sram_bwe      = 4'h0;
                 trans.sram_addr     = trans.last_sram_addr;
                 trans.sram_wdata    = 32'h0;
                 trans.sram_rdata    = vif.TRAM_Q;
                 trans.sbus_hrdata   = vif.sbus_hrdata_s_o;
                 trans.state         = vif.state_i;
                end
                else if (trans.mode_sbus && !trans.sbus_hauser) begin
                 trans.sram_ce       = 1'b0;
                 trans.sram_bwe      = 4'h0;
                 trans.sram_addr     = 32'h0;
                 trans.sram_wdata    = 32'h0;
                 trans.sram_rdata    = 32'h0;
                 trans.sbus_hrdata   = 32'h0;
                 trans.state         = vif.state_i;
                end
                else if (trans.sbus_hwrite && !trans.mode_sbus && trans.sbus_hauser) begin
                 trans.sbus_hwdata   = vif.sbus_hwdata_s_i;
                 trans.sram_ce       = vif.TRAM_CE;
                 trans.sram_bwe      = vif.TRAM_BWE;
                 trans.sram_addr     = vif.TRAM_A;
                 trans.sram_wdata    = vif.TRAM_D;
                 trans.sram_rdata    = 32'h0;
                 trans.sbus_hrdata   = 32'h0;
                 trans.state         = vif.state_i;
                end
                trans.sbus_hready_o = vif.sbus_hready_s_o;
                trans.sbus_hresp    = vif.sbus_hresp_s_o;
                // `uvm_info("AHB_MONITOR", $sformatf("Monitor 1 capture from DUT to SB trans: %s", trans.sprint()), UVM_MEDIUM)
                ap.write(trans);
            end
            else if (sbus_req && te_req) begin
                trans.src_i           = SRC_SBUS;
                trans.sbus_hsel       = vif.sbus_hsel_s_i;
                trans.sbus_haddr      = vif.sbus_haddr_s_i;
                trans.sbus_htrans     = vif.sbus_htrans_s_i;
                trans.sbus_hwrite     = vif.sbus_hwrite_s_i;
                trans.sbus_hauser     = vif.sbus_hauser_s_i[0];
                trans.sbus_hready_i   = vif.sbus_hready_s_i;
                trans.mode_sbus       = vif.mode_sbus_require_dbgpriv_i;
                trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                trans.state              = vif.state_i;
                case (vif.sbus_hsize_s_i)
                    3'h0:       trans.sbus_hsize = 3'h0;
                    3'h1:       trans.sbus_hsize = 3'h1;
                    default:    trans.sbus_hsize = 3'h2;
                endcase
                
                if (vif.skid_enable) begin
                    @(posedge vif.clk_i);
                    trans.sbus_hsize         = vif.skbf_size ;
                    trans.sbus_hwrite        = vif.skbf_write;
                    trans.sbus_hauser        = vif.skbf_auser;
                    trans.sbus_haddr         = vif.skbf_addr ;
                    trans.state              = vif.state_i;
                    // trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                    // trans.last_sbus_hresp    = vif.sbus_hresp_s_o;
                end
                
                if (!trans.sbus_hwrite) begin
                    do @(posedge vif.clk_i);
                    while (vif.skid_state);
                    // #1ns;
                    trans.last_sram_ce       = vif.TRAM_CE;
                    trans.last_sram_bwe      = 4'h0;
                    trans.last_sram_addr     = vif.TRAM_A;
                    trans.last_sram_wdata    = 32'h0;
                    trans.state              = vif.state_i;
                    // trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                    // trans.last_sbus_hresp    = vif.sbus_hresp_s_o;
                    // `uvm_info("AHB_MONITOR", $sformatf("TEST 2: %s", trans.sprint()), UVM_MEDIUM)
                end
                else begin
                    // #1ns;
                    trans.last_sram_ce       = 1'b0;
                    trans.last_sram_bwe      = 4'h0;
                    trans.last_sram_addr     = 32'h0;
                    trans.last_sram_wdata    = 32'h0;
                    trans.state              = vif.state_i;
                    // trans.last_sbus_hready_o = vif.sbus_hready_s_o;
                    // trans.last_sbus_hresp    = vif.sbus_hresp_s_o;
                end

                do begin
                    @(posedge vif.clk_i);
                end while (!vif.sbus_hready_s_o);
                if (!trans.sbus_hwrite) begin
                 trans.sram_ce       = trans.last_sram_ce;
                 trans.sram_bwe      = 4'h0;
                 trans.sram_addr     = trans.last_sram_addr;
                 trans.sram_wdata    = 32'h0;
                 trans.sram_rdata    = vif.TRAM_Q;
                 trans.sbus_hrdata   = vif.sbus_hrdata_s_o;
                 trans.sbus_hready_o = vif.sbus_hready_s_o;
                 trans.sbus_hresp    = vif.sbus_hresp_s_o;
                 trans.state         = vif.state_i;
                end
                else if (trans.mode_sbus && !trans.sbus_hauser) begin
                 trans.sram_ce       = 1'b0;
                 trans.sram_bwe      = 4'h0;
                 trans.sram_addr     = 32'h0;
                 trans.sram_wdata    = 32'h0;
                 trans.sram_rdata    = 32'h0;
                 trans.sbus_hrdata   = 32'h0;
                 trans.sbus_hrdata   = vif.sbus_hrdata_s_o;
                 trans.sbus_hready_o = vif.sbus_hready_s_o;
                 trans.sbus_hresp    = vif.sbus_hresp_s_o;
                 trans.state         = vif.state_i;
                end
                else if (trans.sbus_hwrite) begin
                    // do @(posedge vif.clk_i);
                    // while (vif.skid_state);
                    trans.sbus_hwdata   = vif.sbus_hwdata_s_i;
                    trans.sram_ce       = vif.TRAM_CE;
                    trans.sram_bwe      = vif.TRAM_BWE;
                    trans.sram_addr     = vif.TRAM_A;
                    trans.sram_wdata    = vif.TRAM_D;
                    trans.sbus_hready_o = vif.sbus_hready_s_o;
                    trans.sbus_hresp    = vif.sbus_hresp_s_o;
                    trans.sram_rdata    = 32'h0;
                    trans.sbus_hrdata   = 32'h0;
                    trans.state         = vif.state_i;
                end
                // `uvm_info("AHB_MONITOR", $sformatf("Monitor 2 capture from DUT to SB trans: %s", trans.sprint()), UVM_MEDIUM)
                ap.write(trans);
            end
        end
    endtask
endclass