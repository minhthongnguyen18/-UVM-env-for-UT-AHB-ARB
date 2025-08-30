class ahb_env extends uvm_env;
    te_agent       te_ag;
    sbus_agent     sbus_ag;
    ahb_scoreboard sb;
    
    `uvm_component_utils(ahb_env)
    
    function new(string name = "apb_env", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        te_ag   = te_agent::type_id::create("te_ag", this);
        sbus_ag = sbus_agent::type_id::create("sbus_ag", this);
        sb      = ahb_scoreboard::type_id::create("sb", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        te_ag.monitor.ap.connect(sb.te_exp);
        sbus_ag.monitor.ap.connect(sb.sbus_exp);
    endfunction
endclass