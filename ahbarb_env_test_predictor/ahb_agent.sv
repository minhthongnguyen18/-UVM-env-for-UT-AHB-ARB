class te_agent extends uvm_agent;
    te_driver    driver;
    te_monitor   monitor;
    te_sequencer sequencer;
    
    virtual ahb_if  vif;
    
    uvm_analysis_port#(ahb_transaction) ap;
    
    `uvm_component_utils(te_agent)
    
    function new(string name = "te_agent", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = te_monitor::type_id::create("monitor", this);
        ap      = new("ap", this);
        
        if (get_is_active() == UVM_ACTIVE) begin
            driver         = te_driver::type_id::create("driver", this);
            sequencer      = te_sequencer::type_id::create("sequencer", this);
        end
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("TE AGENT", "TE Virtual Interface not found");
        driver.vif  = vif;
        monitor.vif = vif;
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(ap);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass

class sbus_agent extends uvm_agent;
    virtual ahb_if  vif;
    sbus_driver    driver;
    sbus_monitor   monitor;
    sbus_sequencer sequencer;
    
    uvm_analysis_port#(ahb_transaction) ap;
    
    `uvm_component_utils(sbus_agent)
    
    function new(string name = "sbus_agent", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = sbus_monitor::type_id::create("monitor", this);
        ap      = new("ap", this);
        
        if (get_is_active() == UVM_ACTIVE) begin
            driver         = sbus_driver::type_id::create("driver", this);
            sequencer      = sbus_sequencer::type_id::create("sequencer", this);
        end
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("SBUS AGENT", "SBUS Virtual Interface not found");
        driver.vif  = vif;
        monitor.vif = vif;
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.ap.connect(ap);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass