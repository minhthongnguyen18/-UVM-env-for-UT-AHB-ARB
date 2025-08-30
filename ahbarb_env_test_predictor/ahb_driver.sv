class te_driver extends uvm_driver #(ahb_transaction);
    virtual ahb_if vif;
    
    //Register with UVM macros
    `uvm_component_utils(te_driver)
    
    //Construction
    function new (string name = "te_driver", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("AHB DRIVER", "TE Virtual Interface not found")
    endfunction
    
    task run_phase(uvm_phase phase);
        ahb_transaction req;
        
        //Initialize signals
        vif.reset_bus();
        forever begin
            // Get transaction from sequencer
            seq_item_port.get_next_item(req);
            //Drive the transaction
            drive_te_transaction(req);
            //Transaction complete
            seq_item_port.item_done();
        end
    endtask
    
    task drive_te_transaction(ahb_transaction trans);
        // trans.src_i             = SRC_TE;
        // trans.te_hsize          = 2;
        // trans.te_hwrite         = 1;
        //AP
        vif.te_haddr_s_i                    = trans.te_haddr;
        vif.te_hready_s_i                   = trans.te_hready_i;
        vif.te_htrans_s_i                   = HTRANS_NONSEQ;
        // vif.te_htrans_s_i                   = trans.te_htrans;
        vif.te_hsize_s_i                    = trans.te_hsize;
        vif.te_hwrite_s_i                   = trans.te_hwrite;
        vif.te_hauser_s_i                   = trans.te_hauser;
        @(posedge vif.clk_i);
        //DP
        // vif.te_htrans_s_i                   = HTRANS_IDLE;
        vif.te_hwdata_s_i                   = trans.te_hwdata;
        vif.te_htrans_s_i                   = trans.te_htrans;
        vif.te_hwrite_s_i                   = trans.te_hwrite;
        @(posedge vif.clk_i);
    endtask
endclass

class sbus_driver extends uvm_driver #(ahb_transaction);
    virtual ahb_if vif;
    
    //Register with UVM macros
    `uvm_component_utils(sbus_driver)
    
    //Construction
    function new (string name = "sbus_driver", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("AHB DRIVER", "TE Virtual Interface not found")
    endfunction
    
    task run_phase(uvm_phase phase);
        ahb_transaction req;
        
        //Initialize signals
        vif.reset_bus();
        forever begin
            // Get transaction from sequencer
            seq_item_port.get_next_item(req);
            //Drive the transaction
            drive_sbus_transaction(req);
            //Transaction complete
            seq_item_port.item_done();
        end
    endtask
    
    task drive_sbus_transaction(ahb_transaction trans);
        // trans.src_i            = SRC_SBUS;
        //AP
        vif.sbus_hready_s_i    = trans.sbus_hready_i;
        vif.sbus_hsel_s_i      = 1'b1;
        vif.sbus_haddr_s_i     = trans.sbus_haddr;
        vif.sbus_hsize_s_i     = trans.sbus_hsize;
        vif.sbus_htrans_s_i    = HTRANS_NONSEQ;
        // vif.sbus_htrans_s_i    = trans.sbus_htrans;
        vif.sbus_hwrite_s_i    = trans.sbus_hwrite;
        vif.sbus_hauser_s_i    = trans.sbus_hauser;
        vif.TRAM_Q             = trans.sram_rdata;
        vif.mode_sbus_require_dbgpriv_i    = trans.mode_sbus;
        @(posedge vif.clk_i)
        //DP
        vif.sbus_hsel_s_i      = trans.sbus_hsel;
        vif.sbus_hwdata_s_i    = trans.sbus_hwdata;
        vif.sbus_htrans_s_i    = trans.sbus_htrans;
        vif.mode_sbus_require_dbgpriv_i     = 0;
        // vif.sbus_htrans_s_i    = HTRANS_IDLE;
        // vif.sbus_htrans_s_i    = vif.mode_sbus_require_dbgpriv_i ? HTRANS_IDLE : HTRANS_NONSEQ;
        //Wait for hready_s_o assert
        do @(posedge vif.clk_i);
        while (!vif.sbus_hready_s_o);
        // vif.sbus_htrans_s_i    = HTRANS_IDLE;
        vif.sbus_hsel_s_i      = trans.sbus_hsel;
        vif.sbus_htrans_s_i    = trans.sbus_htrans;
        if (!trans.sbus_hwrite) begin
            trans.sbus_hrdata = vif.sbus_hrdata_s_o;
        end
    endtask
endclass