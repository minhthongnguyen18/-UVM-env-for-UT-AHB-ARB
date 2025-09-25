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
        // @(posedge vif.clk_i);
        //AP
        vif.te_haddr_s_i                    = trans.te_haddr;
        vif.te_hready_s_i                   = trans.te_hready_i;
        vif.te_htrans_s_i                   = trans.te_htrans;
        vif.te_hsize_s_i                    = trans.te_hsize;
        vif.te_hwrite_s_i                   = trans.te_hwrite;
        vif.te_hauser_s_i                   = trans.te_hauser;
        vif.te_hwdata_s_i                   = trans.te_hwdata;
        // `uvm_info("DRIVER", $sformatf("Access Phase: %s", trans.sprint()), UVM_MEDIUM)
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
        // @(posedge vif.clk_i);
        vif.sbus_hready_s_i                = trans.sbus_hready_i;
        vif.sbus_hsel_s_i                  = trans.sbus_hsel;
        vif.sbus_haddr_s_i                 = trans.sbus_haddr;
        vif.sbus_hsize_s_i                 = trans.sbus_hsize;
        vif.sbus_htrans_s_i                = trans.sbus_htrans;
        vif.sbus_hwrite_s_i                = trans.sbus_hwrite;
        vif.sbus_hwdata_s_i                = trans.sbus_hwdata;
        vif.sbus_hauser_s_i                = trans.sbus_hauser;
        vif.TRAM_Q                         = trans.sram_rdata;
        vif.mode_sbus_require_dbgpriv_i    = trans.mode_sbus;
        // `uvm_info("DRIVER", $sformatf("SB Access Phase: %s", trans.sprint()), UVM_MEDIUM)
        @(posedge vif.clk_i);
        // vif.sbus_hwdata_s_i                = trans.sbus_hwdata;
    endtask
endclass